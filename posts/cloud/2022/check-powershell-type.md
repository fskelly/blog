---
title: "Check Powershell Console Type"
slug: check-powershell-type
description: >-
  I have been working with some Microsoft Hybrid technologies. My specific example here is around Azure Arc enabled VMware vSphere aspects. Wh...
added: 2022-09-14T11:14:30+01:00
tags:
  - powershell
  - hybrid
---
I have been working with some Microsoft Hybrid technologies. My specific example here is around [Azure Arc-enabled VMware vSphere](https://docs.microsoft.com/en-us/azure/azure-arc/vmware-vsphere/overview) aspects. When running the scripts provided here there is a key aspect.

**Do NOT run this in the PowerShell ISE.**  

Even with this strong recommendation, it is often accidentally used as it is really easy to perform this action with a right click option and this got me to thinking about how can I check this via code?

So I did some thinking and found a way to check which console type you are running. Below is sample code but will exit the script if the Console Type is ISE.  

## How do we check this and prevent this? ##

```powershell
$consoleType = get-host
if ($consoleType.Name -match 'ise')
{
    $message = "You should NOT use the ISE window, please reload in PowerShell window"
    Write-Output $message
    $message = "This process will terminate shortly"
    Write-Output $message
    Start-Sleep -Seconds 10
    break
} else {
    $message = "good to go"
    Write-Output $message
}
```

Very simple fix but can save hours of troubleshooting.

You may even notice the change to **write-output** from **write-host** as part of [Cross platform support](https://devblogs.microsoft.com/powershell/using-psscriptanalyzer-to-check-powershell-version-compatibility/)


