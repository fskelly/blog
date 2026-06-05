---
title: "Azure VMware Solution How Do I 'Monitor my SDDC Deployment'"
slug: azure-vmware-solution-how-do-i-monitor-sddc-deployment
description: >-
  What are we doing? As I spend more time with my customers and my teams within my organization, I am learning that there a lot of aspects of...
added: 2023-11-21T09:54:43Z
tags:
  - getting-started
  - how-do-i
  - information
draft: true
---
## What are we doing?

As I spend more time with my customers and my teams within my organization, I am learning that there a lot of aspects of Azure VMware Solution that we take for granted and simply skim over as we assume (badly) that everyone knows exactly how to "the basics". With this series of "How Do I" posts, I am going to try and address some of the more common questions that I get asked and hopefully provide some useful information to help you on your Azure VMware Solution journey. I will endeavour to copy as many topics as I can and I am always open to ideas and suggestions. You can reach out to me on [Twitter](https://www.twitter.com/fskelly) or post a suggestion for the log on [GitHub](https://github.com/fskelly/flkelly-cloudblog/issues) - please remember these are designed to be short and sweet and not full blown tutorials.

For the start of this "series", it will most likely cover topics or aspects that affect me day to day with multiple deployments and customers. As time goes on, I will try and expand the topics to cover more and more aspects of Azure VMware Solution.

### How do I monitor an Azure VMware Solution deployment?

I often need to to deploy an !avsAzure VMware Solution Software Defined Data Center (SDDC) and then monitor the deployment to ensure that it is successful. I have a PowerShell script that monitors this for me and allows me to continue with other work. It works by getting the deployment status of the SDDC and then checking the status every 5 minutes until the deployment is complete. Once the deployment is complete, it will display a completed message and then you add whatever notification method you want. I save this file as [deployment-check.ps1](https://github.com/fskelly/flkelly-cloudblog/blob/main/blogFiles/2023/Azure-VMware-Solution-how-do-I/deployment-check/deployment-check.ps1).

**I am well aware and hve contributed to the [Enterprise-Scale-For-AVS](https://github.com/Azure/Enterprise-Scale-for-AVS), these are designed to augment this or to be used on their own and are not a replacement for the Enterprise-Scale-For-AVS scripts - if used by your organization.**

I do have a bit of a backlog for some of these "how-to's" so I will try and get them out as quickly as I can. If you have any suggestions or ideas, please let me know.

```powershell
<#
.SYNOPSIS
This script checks the deployment status of private clouds and monitors the provisioning process.

.DESCRIPTION
The script prompts the user to monitor a deployment or skip the deployment check. If the user chooses to monitor, it retrieves a list of private clouds and allows the user to select a private cloud to check the deployment status. It then continuously checks the provisioning status of the selected private cloud until it is no longer in the "Building" state.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
.\deployment-check.ps1
Prompts the user to monitor a deployment and select a private cloud to check the deployment status.

.NOTES
Author: Your Name
Date: Current Date
#>

#deployment check
Write-Output "Waiting 60 seconds before checking deployment status"
Start-Sleep -s 60
$YesOrNo = Read-Host "Do you need to monitor a deployment (y/n)"
while("y","n" -notcontains $YesOrNo ) {
 $YesOrNo = Read-Host "Please enter your response (y/n)"
}
if ($YesOrNo -eq "y") {
    Write-Output "Monitoring deployment"
} else {
    Write-Output "Skipping deployment check"
    break
}

$privateClouds = Get-AzVMwarePrivateCloud
[int]$privateCloudCount = $privateClouds.count
Write-output "Found $privateCloudCount private clouds"

$i = 0
foreach ($privateCloud in $privateClouds)
{
  $cloudValue = $i
  $cloudText = [string]$cloudValue + " : " + $privateCloud.Name + " ( " + $privateCloud.ResourceGroupName + " )" + ":" + $privateCloud.Location
  Write-output $cloudText
  $i++
}
Do 
{
  [int]$privateCloudChoice = read-host -prompt "Select a private to check deployment & press enter"
} 
until ($privateCloudChoice -le $privateCloudCount)
$selectedprivateCloud = "You selected " + $privateClouds[$privateCloudChoice].Name
Write-output $selectedprivateCloud

$privateCloudRgName = $privateClouds[$privateCloudChoice].resourcegroupname
$privateCloudLocation = $privateClouds[$privateCloudChoice].location
$cloudName = $privateClouds[$privateCloudChoice].name
$privateCloud = Get-AzVMwarePrivateCloud -ResourceGroupName $privateCloudRgName -Name $cloudName

do {
    $privateCloud = Get-AzVMwarePrivateCloud -ResourceGroupName $privateCloudRgName -Name $cloudName
    $provisioningStatus = $privateCloud.provisioningState
    $timestamp = get-date -Format "dd-MM-yyyy - HH:mm:ss"
    switch ($provisioningStatus) {
        "Building" 
        {
            $statusMessage = "Provisioning status for $cloudName is : " +    $provisioningStatus + " ($timestamp)"
            Write-Output $statusMessage
            Start-Sleep -Seconds 300
       }
        "Succeeded"
        {
            $statusMessage = "Provisioning status for $cloudName is : " + $provisioningStatus + " ($timestamp)"
            Write-Output $statusMessage
            break
       }
        Default
        {
            Start-Sleep -Seconds 300
            $statusMessage = "Provisioning status for $cloudName is : " + $provisioningStatus + " ($timestamp)"
            Write-Output $statusMessage
        }
   }
   } until ($provisioningStatus -ne "Building" )

```

