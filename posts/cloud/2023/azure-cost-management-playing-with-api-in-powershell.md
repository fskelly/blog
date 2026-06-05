---
title: "Can I run this cheaper? Use case for the Azure Cost Management API"
slug: azure-cost-management-playing-with-api-in-powershell
description: >-
  What are we doing? I was given inspiration by a colleague, Ben Hummerstone who used a Azure Python Function, whilst super cool and interesti...
added: 2023-08-03T15:24:21+01:00
tags:
  - azure
  - cost-management
categories:
  - azure
  - azure-native
draft: true
---
## What are we doing?

I was given inspiration by a colleague, [Ben Hummerstone](https://www.linkedin.com/in/bhummerstone/) who used a [Azure Python Function](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=asgi%2Capplication-level&pivots=python-mode-configuration), whilst super cool and interesting, I am a PowerShell advocate through and through. So I used PowerShell and wrote a script to show some of the use cases. This is just the tip of the iceberg and the script has been built to show some of the options available.

## Constraints / limitations

1. The primary focus of this script is IaaS.
1. Could be better implemented as a function. If there is enough of an ask, I might build this into a function.
1. Built for my sample use cases.
1. This is a quick and dirty implementation.
1. This is **NOT PRODUCTION** ready yet.

## Lets build this

### Steps

You will need the following

1. PowerShell
2. An understanding of the Cost API (Insert link here)
3. Willingness to learn and experiment
4. Postman or the Postman VS Code extension is great for testing, however a normal browser will also return the required details.

In essence, there are snippets of code built into one bigger script.  

1. Login and list all subscriptions you have access to then pick one to get the vms against.
2. Check for vms with the same in different resource groups.
3. We perform an overall call for data.
4. Check for pagination - as the results are returned 100 rows at a time.
5. We filter the data - we remove Spot and Low Priority Items.
6. We find cheaper options with the above filter applied.
7. We can check against specific regions, again with the filter from step2 applied. Was interesting to get the formatting correct here. :)

I will do my best to explain the script, I have also added comments. Please use this as a base and modify as needed. This scripts only **GETS** information, there are **NO WRITES/SETS** in this script. This is by design, please add this functionality yourself.  

The snippet below, is designed to allow you to log into Azure (Azure Commercial by default) and then list all the subscriptions you have access to and present a list and then connect to the selected subscription.

```powershell
function Select-SubscriptionsAndConnectTo {
    Login-AzAccount
    $subscriptions = Get-AzSubscription | Select-Object Name,SubscriptionId | Sort-Object Name 
    [int]$subscriptionCount = $subscriptions.count
    Write-output "Found" $subscriptionCount "Subscriptions"
    $i = 0
    foreach ($subscription in $subscriptions)
    {
        $subValue = $i
        $subText = [string]$subValue + " : " + $subscription.Name + " ( " + $subscription.SubscriptionId + " ) "
        Write-output $subText
        $i++
    }
    Do 
    {
        [int]$subscriptionChoice = read-host -prompt "Select number & press enter"
    } 
    until ($subscriptionChoice -le $subscriptionCount)

    $selectedSub = "You selected " + $subscriptions[$subscriptionChoice].Name
    Write-output $selectedSub
    Set-AzContext -SubscriptionId $subscriptions[$subscriptionChoice].SubscriptionId
}

Select-SubscriptionsAndConnectTo

```

Get VMs and check if the same VM name is used in multiple resource groups.

```powershell
## getting all vms in a subscription
$vms = Get-AzVM
$vms | Select-Object Name,ResourceGroupName,Location,@{l='VMSize';e={$_.HardwareProfile.VmSize}}| Sort-Object Name | Format-Table -AutoSize
## reading in virtual machines
$selectedVmName = read-host "Which VM would you like to check for better pricing?"
$selectedRGName = $vms | Where-Object { $_.Name -eq $selectedVmName } | Select-Object ResourceGroupName

## checking for duplicate names in multiple resource groups
if ($selectedRGName.count -gt 1)
{
    $rgCount = $selectedRGName.count
    Write-Output "Found multiple VMs with the same name in different resource groups"
    $rgNames = $selectedRGName | Select-Object ResourceGroupName
    #write-output $rgNames.resourcegroupname
    $i = 0
    foreach ($rgName in $rgNames)
    {
        $rgValue = $i
        $rgText = [string]$rgValue + " : " + $rgName.ResourceGroupName
        Write-output $rgText
        $i++
    }
    Do 
    {
        [int]$rgChoice = read-host -prompt "Select number & press enter"
    } 
    until ($rgChoice -le $rgCount-1)

    $selectedRGText = "You selected " + $selectedRGName[$rgChoice].ResourceGroupName
    Write-output $selectedRGText
    $selectedRG = $selectedRGName[$rgChoice].ResourceGroupName

    ## selecting the vm from the selected resource group
    $azureVm = get-azvm -ResourceGroupName $selectedRG -Name $selectedVmName
} else {
    ## selecting the vm from the selected resource group
    $azureVm = get-azvm -ResourceGroupName $selectedRGName.ResourceGroupName -Name $selectedVmName
}

```

Getting information about the selected VM and establishing the current base price.

```powershell
## building variables for api call
$azureVMSKU = $azureVm.HardwareProfile.VmSize
$azureVmLocation = $azureVm.Location

## api variables
$apiUrl = "https://prices.azure.com/api/retail/prices?"
$armSkuName = $azureVMSKU

## get base information around pricing

$baseFilter = "armSkuName eq '$armSkuName' and priceType eq 'Consumption' and armRegionName eq '$azureVmLocation'"
$baseUrl = $apiUrl + "`$filter=$baseFilter"
Write-Output "Current Url is $baseUrl"
$baseJsonData = Invoke-RestMethod -Uri $baseUrl -Method Get
## selecting most expensive price
$baseVMPrice = ($baseJsonData.Items  | Where-Object { $_.skuName -notlike "*Spot*" -and $_.skuName -notlike "*Low Priority*" } | Sort-Object unitPrice -Descending | Select-Object -Last 1).unitPrice

## formatting for results
$baseVMPrice = "{0:N4}" -f $baseVMPrice
Write-Output "Base price is $baseVMPrice"

```

Build an array to store the information for later manipulation and sorting. Filter out "Low Priority" and "Spot VMs" and deal with pagination.

```powershell

## get all pricing data for the selected vm
$filter = "armSkuName eq '$armSkuName' and priceType eq 'Consumption'"
$allItems = @()

# Run Query
$url = $apiUrl + "`$filter=$filter"
Write-Output "Current Url is $url"
$currentJsonData = Invoke-RestMethod -Uri $url -Method Get
$allItems += $currentJsonData.Items

# pagination
$NextPage = $currentJsonData.NextPageLink
while ($NextPage) {
    Write-Verbose "Current Url is $NextPage"
    $currentJsonData = Invoke-RestMethod -Uri $NextPage -Method Get
    $allItems += $currentJsonData.Items
    $NextPage = $currentJsonData.NextPageLink
}

# filter out spot and low priority item from array
$filteredItems = $allItems | Select-Object skuName, meterName, unitOfMeasure, @{l='unitPrice';e={"{0:N4}" -f $_.unitPrice}}, armRegionName | Where-Object { $_.skuName -notlike "*Spot*" -and $_.skuName -notlike "*Low Priority*" }
Write-Output "Total items: $($filteredItems.Count)"
#$filteredItems
$filteredItems | Sort-Object -Property unitPrice | Format-Table -AutoSize
$cheaperOptions = $filteredItems | Where-Object -Property unitPrice -lt $baseVMPrice | Sort-Object -Property unitPrice
Write-Output "Cheaper than $baseVMPrice options: $($cheaperOptions.Count)"
$cheaperOptions | Format-Table -Property skuName, meterName, unitOfMeasure, @{l='unitPrice';e={"{0:N4}" -f $_.unitPrice}}, armRegionName -AutoSize

```

I have also included an option to check against specific regions if that is something you would like to do. You will get prompted if you want to check against other regions. A **Y** will continue to ask which regions, this is a comma seperated list, _swedencentral,westeurope_ (as an example). A **N** will simply stop the script.

```powershell

## how to check against specific regions
$regionCheck = read-host "Would you like to check against specific regions? (y/n)"
while("y","n" -notcontains $regionCheck) {
    $regionCheck = read-host "Would you like to check against specific regions? (y/n)"
}
if ($regionCheck -eq "y")
{
    $specificRegions = read-host "please enter region names separated by comma"
    $specificRegions = $specificRegions.split(",")

    $regionItems = @()
    $regionQueryBaseUrlFilter = "armSkuName eq '$armSkuName' and priceType eq 'Consumption' "
    
    foreach ($item in $specificRegions)
    {
        $item
        $regionQueryBaseUrlFilter = "armSkuName eq '$armSkuName' and priceType eq 'Consumption' "
        $regionQueryBaseUrlFilter = $regionQueryBaseUrlFilter + "and armRegionName eq '$item' "
        $regionQueryBaseUrlFilter
        $regionQueryUrl = $apiUrl + "`$filter=$regionQueryBaseUrlFilter"
        $otherRegionJsonData = Invoke-RestMethod -Uri $regionQueryUrl -Method Get
        $regionItems += $otherRegionJsonData.Items
        $NextPage = $otherRegionJsonData.NextPageLink
        while ($NextPage) {
            Write-Output "Current Url is $NextPage"
            $otherRegionJsonData = Invoke-RestMethod -Uri $NextPage -Method Get
            $regionItems += $otherRegionJsonData.Items
            $NextPage = $otherRegionJsonData.NextPageLink
        }
    }
    
    Write-Output "Output below"
    $regionItems | Where-Object { $_.skuName -notlike "*Spot*" -and $_.skuName -notlike "*Low Priority*" } | Format-Table -Property skuName, meterName, unitOfMeasure, @{l='unitPrice';e={"{0:N4}" -f $_.unitPrice}}, armRegionName -AutoSize
    }
```

Full script can be found [here](https://github.com/fskelly/flkelly-AzureCode-powershell/blob/main/cost-management/get-vms-list-costings.ps1)

