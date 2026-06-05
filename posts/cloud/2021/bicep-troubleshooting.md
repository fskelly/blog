---
title: "Bicep Troubleshooting"
slug: bicep-troubleshooting
description: >-
  A quick post to help with a common 'error' I run into now and then.
added: 2021-07-02T05:40:16+02:00
tags:
  - quick-post
  - bicep
categories:
  - azure
  - iac
---
# Some basic "troubleshooting" with [Azure Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)

So, let me start with this. The team and the community behind Azure Bicep are amazing. There are some great examples [here](https://github.com/Azure/bicep). I often use these as a base and the rip apart or add to meet my needs, you do **NOT** need to start from ground zero. :smile:  

When you are deploying bicep templates you command will look something like this.

```powershell
$bicepFile = ".\main.bicep"
New-AzResourceGroupDeployment -ResourceGroupName <resourceGroupName> -TemplateFile <bicepFilePath> -name <deploymentname>
```

I love to use repeatable code, so mine has more variables and would look like this.

```powershell
## Place Resource Group Name here
$rgName = "testingRG"
## add tags if you want to add metadata
$tags = @{"deploymentMethod"="bicep"; "Can Be Deleted"="yes"}
## location to be deployed into
$rgLocation = "westeurope"

#use this command when you need to create a new resource group for your deployment
$rg = New-AzResourceGroup -Name $rgName -Location $rgLocation 
New-AzTag -ResourceId $rg.ResourceId -Tag $tags

## bicep Deployment
## Bicep File name
$bicepFile = ".\main.bicep"
$deploymentName = ($bicepFile).Substring(2) + "-" +(get-date -Format ddMMyyyy-hhmmss) + "-deployment"
New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $bicepFile -name $deploymentName
```

When trying to deploy you might get an error like this.
![deployment errors](/blog/assets/cloud/2021/bicep-troubleshooting/bicepError.png)

And that is very cryptic and **NOT** easy to understand. The easiest fix here is to go back to basics. :smile:

```powershell
az bicep build --file .\main.bicep
```

This will then throw the actual bicep error, and then you can fix your file and deploy again.

Hope this helps you.


