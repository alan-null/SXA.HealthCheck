Import-Function Get-CurrentSxaVersion
Import-Function Get-TenantItem

Class ValidationStep {
    [String]$Title
    [String]$Description
    [System.Object]$Script
    [System.Object]$Version
    [ID[]]$Dependency
    [ValidationResult]$ValidationResult
}

enum Result {
    OK;
    Error;
    Warning
}

class ValidationResult {
    [Result]$Result
    [System.String]$Message
}

function Test-ValidVersion {
    param (
        [ValidationStep]$Step
    )
    $current = Get-CurrentSxaVersion
    $from = $Step.Version.From
    $to = $Step.Version.To
    $from -le $current -and ($to -eq "*" -or $to -ge $current)
}

function Test-Dependency {
    param (
        [ValidationStep]$Step,
        [Sitecore.Data.Fields.MultilistField]$SitesModulesField,
        [Sitecore.Data.Fields.MultilistField]$TenantModulesField
    )
    $unresolved = $Step.Dependency | ? { $_ -ne $null} | ? {
        $SitesModulesField.Contains($_) -eq $false -and $TenantModulesField.Contains($_) -eq $false
    }
    if ($unresolved.Count -eq 0) {
        $true
    }else{
        Write-Host "Skipping step: $($Step.Title) due to lack of required dependencies" -ForegroundColor Gray
        $false
    }
}

function Test-BrokenLink {
    param (
        [Sitecore.Data.Items.Item]$Item,
        [Sitecore.Data.ID]$FieldID
    )
    [ValidationResult]$result = New-Object ValidationResult
    $result.Result = [Result]::OK
    [Sitecore.Data.Fields.ReferenceField]$field = $Item.Fields[$FieldID]
    if ($field.Value -ne $null -and $field.TargetItem -eq $null) {
        $result.Message = "Could not find an item with id: $($field.Value)"
        $result.Result = [Result]::Error
    }
    return $result
}

function New-ResultObject {
    param ()

    [ValidationResult]$result = New-Object ValidationResult
    $result.Result = [Result]::OK
    $result.Message = ""
    $result
}

$steps =
@{
    Title       = "Field 'SiteMediaLibrary'";
    Description = "Checks whether 'SiteMediaLibrary' field contains proper reference to a site specific media library item";
    Version     = @{
        From = 1400;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        [Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Multisite.Templates+Site+Fields]::SiteMediaLibrary

        $temp = Test-BrokenLink $SiteItem $id
        if ($temp.Result -eq [Result]::Error) {
            return $temp
        }

        [ValidationResult]$result = New-ResultObject
        return $result
    }
},
@{
    Title       = "Field 'ThemesFolder'";
    Description = "Checks whether 'ThemesFolder' field contains proper reference to a site specific themes folder item";
    Version     = @{
        From = 1400;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        [Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Multisite.Templates+Site+Fields]::ThemesFolder

        $temp = Test-BrokenLink $SiteItem $id
        if ($temp.Result -eq [Result]::Error) {
            return $temp
        }

        [ValidationResult]$result = New-ResultObject
        return $result
    }
},
@{
    Title       = "Field 'AdditionalChildren'";
    Description = "Checks whether 'AdditionalChildren' field contains proper reference to a tenant shared media library folder and there are no broken links";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-SiteMediaItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Multisite.Templates+Media+Fields]::AdditionalChildren

        $siteMediaItem = Get-SiteMediaItem $SiteItem
        [Sitecore.Data.Fields.MultilistField]$field = $siteMediaItem.Fields[$id]
        $items = $field.GetItems()
        if ($items.Count -ne $field.TargetIDs.Count) {
            $result.Result = [Result]::Error
            $missingIDs = $field.TargetIDs | ? { $items.ID.Contains($_) -eq $false }
            $result.Message = "Could not find items with id: $($missingIDs -join ',')"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Field 'Styles Optimizing Enabled'";
    Description = "Checks 'Styles Optimizing Enabled' field to determine if styles optimization is disabled";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-PageDesignsItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Theming.Templates+_Optimizable+Fields]::StylesOptimisingEnabled

        [Sitecore.Data.Items.Item]$pageDesignItem = Get-PageDesignsItem $SiteItem
        $fieldValue = $pageDesignItem.Fields[$id].Value

        $state = [Sitecore.MainUtil]::GetTristate($fieldValue, [Sitecore.Tristate]::Undefined)
        if ($state -eq [Sitecore.Tristate]::False) {
            $result.Result = [Result]::Warning
            $result.Message = "Styles optimization for yor site is explicitly disabled. This may cause performance problems. </br>You should enable assests optimization on production"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Field 'Scripts Optimizing Enabled'";
    Description = "Checks 'Scripts Optimizing Enabled' field to determine if scripts optimization is disabled";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-PageDesignsItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Theming.Templates+_Optimizable+Fields]::ScriptsOptimisingEnabled

        [Sitecore.Data.Items.Item]$pageDesignItem = Get-PageDesignsItem $SiteItem
        $fieldValue = $pageDesignItem.Fields[$id].Value

        $state = [Sitecore.MainUtil]::GetTristate($fieldValue, [Sitecore.Tristate]::Undefined)
        if ($state -eq [Sitecore.Tristate]::False) {
            $result.Result = [Result]::Warning
            $result.Message = "Scripts optimization for yor site is explicitly disabled. This may cause performance problems. </br>You should enable assests optimization on production"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Theme for Default device";
    Description = "Checks whether any theme is assigned to a default device";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        [ValidationResult]$result = New-ResultObject

        [Sitecore.Data.ID]$defaultDeviceID = "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}"
        $deviceItem = Get-Item master: -ID $defaultDeviceID
        $theme = [Sitecore.XA.Foundation.Theming.ThemingContext]::new().GetThemeItem($siteItem, $deviceItem)

        if ($theme -eq $null) {
            $result.Result = [Result]::Error
            $result.Message = "There is no theme assigned to the Default device"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Theme and Compatible Themes field consistency";
    Description = "Checks whether themes used in Theme-to-Device mapping are compatible with current site";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-PageDesignsItem
        Import-Function Get-SettingsItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$themesMappingFieldID = [Sitecore.XA.Foundation.Theming.Templates+SiteTheme+Fields]::Theme
        [Sitecore.Data.ID]$compatibleThemesFieldIdD = [Sitecore.XA.Foundation.Theming.Templates+_Compatiblethemes+Fields]::Themes

        [Sitecore.Data.Items.Item]$pageDesignItem = Get-PageDesignsItem $SiteItem
        [Sitecore.Data.Items.Item]$settingsItem = Get-SettingsItem $SiteItem

        [Sitecore.XA.Foundation.SitecoreExtensions.CustomFields.MappingField]$themesMappingFields = $pageDesignItem.Fields[$themesMappingFieldID]
        [Sitecore.Data.Fields.MultilistField]$compatibleThemesField = $settingsItem.Fields[$compatibleThemesFieldIdD]
        $incorrectDeviceMapping = $themesMappingFields.Keys | % { $_.ToString() } | ? {
            $key = $_
            $theme = $themesMappingFields.Lookup($key)
            $compatibleThemesField.Items.Contains($theme.ID.ToString()) -eq $false
        }

        if ($incorrectDeviceMapping.Count -gt 0) {
            $result.Result = [Result]::Error
            $result.Message = "Some themes used for mapping are not compatible with current site. Please check themes mapping for following devices: $($incorrectDeviceMapping -join ',')"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Site definitions conflicts";
    Description = "Checks whether current site definitions have any conflicts with other sites";
    Version     = @{
        From = 1500;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-SettingsItem
        Import-Function Get-SxaSiteDefinitions
        [ValidationResult]$result = New-ResultObject

        [Sitecore.Data.Items.Item]$settingsItem = Get-SettingsItem $SiteItem
        $siteDefinitions = $settingsItem.Axes.GetDescendants() | ? { $_.TemplateID -eq "{EDA823FC-BC7E-4EF6-B498-CD09EC6FDAEF}" } | Wrap-Item | % { $_."SiteName" }

        $sites = Get-SxaSiteDefinitions | ? { $siteDefinitions.Contains($_.Name) } | ? { $_.State -eq "Conflict" }

        if ($sites.Count -gt 0) {
            $result.Result = [Result]::Error
            $result.Message = $sites[0].Conflict
            return $result
        }
        return $result
    }
},
@{
    Title       = "Error Handling - 404";
    Description = "Checks whether current site has 404 page configured";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Dependency = @("{8F9355F1-F6AC-49A1-8465-0B905E3E8CAF}");
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-SettingsItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$id = [Sitecore.XA.Feature.ErrorHandling.Templates+_ErrorHandling+Fields]::Error404Page
        [Sitecore.Data.Items.Item]$settingsItem = Get-SettingsItem $SiteItem
        [Sitecore.Data.Fields.InternalLinkField]$field = $settingsItem.Fields[$id]

        if ($field.TargetItem -eq $null) {
            $result.Result = [Result]::Warning
            $result.Message = "Error page for 404 code (Page Not Found) is not configured"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Site name";
    Description = "Validates site name. Site names cannot contain control characters, spaces (' ') semicolons, or commas";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-SettingsItem
        Import-Function Get-SxaSiteDefinitions
        [ValidationResult]$result = New-ResultObject

        [Sitecore.Data.Items.Item]$settingsItem = Get-SettingsItem $SiteItem
        $siteDefinitions = $settingsItem.Axes.GetDescendants() | ? { $_.TemplateID -eq "{EDA823FC-BC7E-4EF6-B498-CD09EC6FDAEF}" } | Wrap-Item
        $current = Get-CurrentSxaVersion
        if($current -ge 1500){
            $siteNames = $siteDefinitions | % { $_."SiteName" }
        }else{
            $siteNames = $siteDefinitions | % { $_.Name }
        }

        [string[]]$invaludNames = $siteNames | ? {
            [regex]::Match($_, "^[a-zA-z0-9]*$").Success -eq $false
        }

        if ($invaludNames.Count -gt 0) {
            $result.Result = [Result]::Error
            $invaludNames = $invaludNames | % { "'<b>$($_)</b>'" }
            $result.Message = "There are site definition items with incorrect site names: $($invaludNames -join ', ')"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Error Handling - 500";
    Description = "Checks whether current site has 500 page configured";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Dependency = @("{8F9355F1-F6AC-49A1-8465-0B905E3E8CAF}");
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        Import-Function Get-SettingsItem
        [ValidationResult]$result = New-ResultObject
        [Sitecore.Data.ID]$id = [Sitecore.XA.Feature.ErrorHandling.Templates+_ErrorHandling+Fields]::Error500Page
        [Sitecore.Data.Items.Item]$settingsItem = Get-SettingsItem $SiteItem
        [Sitecore.Data.Fields.InternalLinkField]$field = $settingsItem.Fields[$id]

        if ($field.TargetItem -eq $null) {
            $result.Result = [Result]::Warning
            $result.Message = "Error page for 500 code (Server Error Page) is not configured"
            return $result
        }

        $sitesWithoutStaticHTML = $settingsItem.Axes.GetDescendants() | `
            ? { $_.TemplateID -eq "{EDA823FC-BC7E-4EF6-B498-CD09EC6FDAEF}" } | Wrap-Item | `
            % { $_."SiteName" } | `
            ? { (Test-Path ([Sitecore.IO.FileUtil]::MapPath("/ErrorPages/$($_).html"))) -eq $false }

        if ($sitesWithoutStaticHTML.Count -gt 0) {
            $result.Result = [Result]::Error
            $result.Message = "There are sites without static HTML error page: $($sitesWithoutStaticHTML -join ', ')"
            return $result
        }
        return $result
    }
},
@{
    Title       = "Maps Provider key";
    Description = "If there is any use of Maps rendering, it checks whether maps provider key has been configured";
    Version     = @{
        From = 1000;
        To   = "*";
    };
    Dependency  = @("{4EE33975-DB00-455E-9F9C-2CB78C892C79}");
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        [ValidationResult]$result = New-ResultObject
        $mapsRenderingID = "{4DD74227-4504-4102-A802-76241F372B9E}"
        $rendering = $SiteItem.Database.GetItem($mapsRenderingID)
        $siteLongID = $SiteItem.Paths.LongID

        $mapsRenderingUsages = [Sitecore.Globals]::LinkDatabase.GetItemReferrers($rendering, $false) | `
            ? { ($_.SourceFieldID -eq [Sitecore.FieldIDs]::LayoutField) -or ($_.SourceFieldID -eq [Sitecore.FieldIDs]::FinalLayoutField) } | `
            ? { $_.TargetDatabaseName -eq $rendering.Database.Name } | `
            % { $rendering.Database.GetItem($_.SourceItemID) } | `
            ? { $_ -ne $null } | `
            ? { $_.Paths.LongID.StartsWith($siteLongID) }

        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $mapsProvider = $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Geospatial.Services.IMapsProvider])
        $key = $mapsProvider.GetMapsKey($SiteItem)


        if ([string]::IsNullOrWhiteSpace($key) -eq $true) {
            if ($mapsRenderingUsages.Count -gt 0) {
                $result.Result = [Result]::Error
                $result.Message = "Found $($mapsRenderingUsages.Count) useages of <b>Maps</b> rendering in selected site but <b>Maps Provider key</b> is empty."
                $mapsRenderingUsages | % { Write-Log "[SXA.HealthCheck][Maps Provider key] $($_.Paths.Path)" }
            }else{
                $result.Result = [Result]::Warning
                $result.Message = "<b>Maps Provider key</b> is empty. If you are not going to use <b>Maps</b> rendering that's fine."
            }
            return $result
        }
        return $result
    }
},
@{
    Title       = "SXA Best practices - unused data sources";
    Description = "Checks whether there are unused data sources present in your site";
    Version     = @{
        From = 1800;
        To   = "*";
    };
    Dependency  = @("{4EE33975-DB00-455E-9F9C-2CB78C892C79}");
    Script      = {
        param(
            [Sitecore.Data.Items.Item]$SiteItem
        )
        [ValidationResult]$result = New-ResultObject
        Import-Function CleanDataFolder

        function Get-RelativeDatasourcePath {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true, Position = 0 )]
                [Item]$Item
            )

            process {
                Import-Function Get-PresentationDetails
                Write-Verbose "Cmdlet Get-RelativeDatasourcePath - Process"
                $presentation = Get-PresentationDetails $item
                $definition = [Sitecore.Layouts.LayoutDefinition]::Parse($presentation)
                $definition.Devices | % {
                    $_.Renderings | ? { $_.Datasource -ne $null } | ? {
                        $_.Datasource.StartsWith([Sitecore.XA.Foundation.LocalDatasources.Constants]::LocalPrefix) -or $_.Datasource.StartsWith([Sitecore.XA.Foundation.LocalDatasources.Constants]::PageRelativePrefix)
                    } | % {
                        $_.Datasource.Replace([Sitecore.XA.Foundation.LocalDatasources.Constants]::LocalPrefix, "").Replace([Sitecore.XA.Foundation.LocalDatasources.Constants]::PageRelativePrefix, "")
                    }
                }
            }
        }

        $item = $SiteItem.Axes.GetDescendants() | ? { $_.TemplateID -eq "{1C82E550-EBCD-4E5D-8ABD-D50D0809541E}" } | Wrap-Item
        $unusedDatasources = $item | % {
            $item = $_.Parent
            $dataFolder = $_

            [Item[]]$dataSources = Get-NestedDatasource $dataFolder

            $dataSourcesPaths = Get-RelativeDatasourcePath $item
            $dataSourcesIds = Get-DataSourcesIdsFromLayout $item

            foreach ($datasource in $dataSources) {
                $usedAsPageRelative = IsDataSourceUsedAsPageRelative $datasource $dataSourcesPaths
                $usedAsGlobal = IsDataSourceUsedAsGlobal $datasource
                $usedAsGlobalOnCurrentPage = IsDataSourceUsedAsGlobalOnCurrentPage $datasource $dataSourcesIds

                if ($usedAsPageRelative -or $usedAsGlobal -or $usedAsGlobalOnCurrentPage) {
                }
                else {
                    Write-Log "[SXA.HealthCheck][Unused data sources] Following data source is probably unused and could be recycled: $($datasource.Paths.Path)"
                    $datasource
                }
            }
        }

        if ($unusedDatasources.Count -gt 0) {
            $result.Result = [Result]::Warning
            $result.Message = "Found unused datasources ($($unusedDatasources.Count)). Open <b>SPE</b> log file to learn more"
        }
        return $result
    }
}

$siteItem = Get-Item .
[Sitecore.Data.ID]$siteTemplateID = [Sitecore.XA.Foundation.Multisite.Templates+Site]::ID
if([Sitecore.Data.Managers.TemplateManager]::GetTemplate($siteItem).InheritsFrom($siteTemplateID) -eq $false){
    Show-Alert "Please select a SXA site`n`nCurrent item: '$($siteItem.Paths.Path)'`nis not a SXA site item"
    return
}


$TenantItem = Get-TenantItem $SiteItem
[Sitecore.Data.ID]$id = [Sitecore.XA.Foundation.Scaffolding.Templates+_Modules+Fields]::Modules
[Sitecore.Data.Fields.MultilistField]$sitesModulesField = $SiteItem.Fields[$id]
[Sitecore.Data.Fields.MultilistField]$tenantModulesField = $TenantItem.Fields[$id]

Write-Host "Validating site: $($siteItem.Paths.Path)" -ForegroundColor Cyan

# Icon mapping
$modeMapping = @{}
$modeMapping[[Result]::Warning] = "\Images\warning.png"
$modeMapping[[Result]::Error] = "\Images\error.png"
$modeMapping[[Result]::OK] = "\Images\check.png"

$steps | `
    ? { Test-ValidVersion $_ } | `
    ? { Test-Dependency $_  $sitesModulesField $tenantModulesField } | `
    % {
    [ValidationStep]$step = $_
    Write-Host "`nValidation step: $($step.Title)" -ForegroundColor Cyan

    [ValidationResult]$result = Invoke-Command -Script $step.Script -Args $siteItem
    $step.ValidationResult = $result
    if ($result.Result -eq [Result]::Error) {
        Write-Host $result.Message -ForegroundColor Red
    }
    if ($result.Result -eq [Result]::Warning) {
        Write-Host $result.Message -ForegroundColor Yellow
    }
    if ($result.Result -eq [Result]::OK) {
        Write-Host $result.Message -ForegroundColor Green
    }
    $step

} | Show-ListView  `
    -PageSize 25 `
    -Property `
        @{Label = "Title"; Expression = { $_.Title } },
        @{Label = "Icon"; Expression = { $modeMapping[$_.ValidationResult.Result] } },
        @{Label = "Description"; Expression = { $_.Description } },
        @{Label = "Message"; Expression = { $_.ValidationResult.Message } }
