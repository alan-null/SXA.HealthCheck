[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alan-null/SXA.HealthCheck/master/main.ps1" -UseBasicParsing
if ($response.StatusCode -eq 200) {
    $body = $response.Content
    $indexStart = $body.IndexOf("Class ValidationStep")
    $index = $body.IndexOf("`$siteItem = Get-Item .")
    $steps = $body.Substring($indexStart, $index - $indexStart)
    $steps = $steps.Replace("[ID[]]", "[object[]]")
    Invoke-Expression $steps
    '# Validation steps'
    '| Title   |      Description      |  From | To |'
    "|----------|:-------------|:------|:------|"
    $steps | Sort-Object -Property @{ Expression = { $_.Version.From }; Descending = $false } , @{ Expression = { $_.Title } ; Ascending = $true } | % {
        $title = $_.Title
        $description = $_.Description
        $verFrom = $_.Version.From
        $verTo = $_.Version.To
        "| **$title** | $description | ``$verFrom`` | ``$verTo`` |"
    }
}