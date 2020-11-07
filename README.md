# SXA.HealthCheck

**SXA.HealthCheck** is a Power Shell script used to determine health status of SXA site.

It consists of validation steps. Each step checks different thing in SXA solution and provides possible solution

## Usage

### Executing

1. Open the latest version of [**main.ps1**](https://raw.githubusercontent.com/alan-null/SXA.HealthCheck/master/main.ps1)
2. Copy content to a clipboard
3. Open PowerShell ISE (`http://domain/sitecore/shell/Applications/PowerShell/PowerShellIse?sc_bw=1`)
4. Paste content from a clipboard
5. Set **Context item** to your site (for example `/sitecore/content/F/Validation/V`). If you are not familiar you can read more [here](https://doc.sitecorepowershell.com/interfaces/scripting)
6. Execute script

Steps will be executed one by one and you will see continuous results on the console.

![console](https://user-images.githubusercontent.com/6848691/47311509-388cd100-d63a-11e8-95a3-5a86e134ee03.png)

Once the whole procedure is done you will see List View with validation results

![list-view](https://user-images.githubusercontent.com/6848691/47311513-3c205800-d63a-11e8-9ffc-9898b902bfc7.png)

### Executing - remote script

If you want to automate validation process and get the most recent version simply invoke this expression

```PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alan-null/SXA.HealthCheck/master/main.ps1" -UseBasicParsing
if($response.StatusCode -eq 200){
    Invoke-Expression $response.Content
}
```

It will fetch the latest version of [**main.ps1**](https://raw.githubusercontent.com/alan-null/SXA.HealthCheck/master/main.ps1) script and let you invoke it inside **ISE**.

### Reading results

There are 3 possible results of validation:

* **OK** - you can celebrate, a validation step was successful,
* **Warning** - something has been found but it is not considered as a serious problem (perhaps you are still configuring your site or you set something explicitly to work as a developer). Treat it as a good advice but remember to review results before you publish your site,
* **Error** - steps with this type of result must be solved.

For **Error** and **Warning** you will see message in the 4th column. It describes the problem and suggests what you could do to solve it

## Validation steps

| Title                                                             | Description                                                                                                                               | From   | To   |
| ----------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------- | :----- | :--- |
| **Error Handling - 404**                                          | Checks whether current site has 404 page configured                                                                                       | `1000` | `*`  |
| **Error Handling - 500**                                          | Checks whether current site has 500 page configured                                                                                       | `1000` | `*`  |
| **Field 'AdditionalChildren'**                                    | Checks whether 'AdditionalChildren' field contains proper reference to a tenant shared media library folder and there are no broken links | `1000` | `*`  |
| **Field 'Scripts Optimizing Enabled'**                            | Checks 'Scripts Optimizing Enabled' field to determine if scripts optimization is disabled                                                | `1000` | `*`  |
| **Field 'Styles Optimizing Enabled'**                             | Checks 'Styles Optimizing Enabled' field to determine if styles optimization is disabled                                                  | `1000` | `*`  |
| **Maps Provider key**                                             | If there is any use of Maps rendering, it checks whether maps provider key has been configured                                            | `1000` | `*`  |
| **Site name**                                                     | Validates site name. Site names cannot contain control characters, spaces (' ') semicolons, or commas                                     | `1000` | `*`  |
| **SXA Best practices - custom items under SXA nodes**             | Checks whether there are additional or modified files under SXA nodes                                                                     | `1000` | `*`  |
| **SXA Best practices - limit the number of renderings on a page** | Checks whether there are pages with more than 30 renderings                                                                               | `1000` | `*`  |
| **SXA Best practices - media under virtual media folder**         | Checks whether there are media items stored directly under virtual media folder                                                           | `1000` | `*`  |
| **Theme and Compatible Themes field consistency**                 | Checks whether themes used in Theme-to-Device mapping are compatible with current site                                                    | `1000` | `*`  |
| **Theme for Default device**                                      | Checks whether any theme is assigned to a default device                                                                                  | `1000` | `*`  |
| **Field 'SiteMediaLibrary'**                                      | Checks whether 'SiteMediaLibrary' field contains proper reference to a site specific media library item                                   | `1400` | `*`  |
| **Field 'ThemesFolder'**                                          | Checks whether 'ThemesFolder' field contains proper reference to a site specific themes folder item                                       | `1400` | `*`  |
| **Site definitions conflicts**                                    | Checks whether current site definitions have any conflicts with other sites                                                               | `1500` | `*`  |
| **SXA Best practices - unused data sources**                      | Checks whether there are unused data sources present in your site                                                                         | `1800` | `*`  |