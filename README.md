# SXA.HealthCheck

**SXA.HealthCheck** is a Power Shell script used to determine health status of SXA site.

I contains a set of steps. Each step checks different thing in SXA solution and provies possible solution


# Usage

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


### Reading results

There are 3 possible results of validation:

* **OK** - you can celebrate, a validation step was successful,
* **Warning** - something has been found but it is not considered as a serious problem (perhaps you are still configuring your site or you set something explicitly to work as a developer). Treat it as a good advice but remember to review results before you publish your site,
* **Error** - steps with this type of result must be solved.

For **Error** and **Warning** you will see message in the 4th column. It describes the problem and suggests what you could do to solve it