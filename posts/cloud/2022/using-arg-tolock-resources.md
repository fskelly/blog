---
title: "Using Azure Resource Graph and Tags to lock items in Azure"
slug: using-arg-tolock-resources
description: >-
  What are we doing? We are going to use Azure Resource Graph to find items with a specific tag, in this case {"toBeLocked"="Yes"} and then pl...
added: 2022-10-03T13:59:06+01:00
tags:
  - powershell
  - azure-resource-graph
categories:
  - azure
  - azure-resource-graph
draft: true
---
## What are we doing?

We are going to use Azure Resource Graph to find items with a specific tag, in this case *{"toBeLocked"="Yes"}* and then place a resource lock on them.

## Constraints / limitations

1. Use Azure Resource Graph to perform the search. Very fast and gives you a new way to interface with Azure Resources.
1. As part of this post, I am giving samples below to create items, you could use these for testing. Please test and make sure with production environment.
1. You are using an account that can create locks and potentially remove if needed during the testing.

## Lets build this

### Steps

1. Create sample items
1. Build Azure Resource Graph Queries
1. Getting items from the query programmatically
1. Adding locks
1. Result

### Create sample items to lock

```powershell
## create resource group
$rgName = "toberesourcelocked"
$rgLocation = "northeurope"
$rg = new-azresourcegroup -name $rgname -location $rgLocation

## create items
$guid = New-Guid
$saName = "sa"
$saSuffix = $guid.ToString().Split("-")[0]+$guid.ToString().Split("-")[1]
$saName = (($saName.replace("-",""))+$saSuffix)
New-AzStorageAccount -ResourceGroupName $rgName -Name $saName -Location $rgLocation -AccountType Standard_LRS

## create tag(s)
$tags = @{"toBeLocked"="Yes"}

## get items in Resource Group and tag them
$items = Get-AzResource -ResourceGroupName $rgName
foreach ($item in $items)
{
    Update-AzTag -ResourceId $item.ResourceId -Tag $tags -Operation Replace
} 
## update resource group with tag(s)
Update-AzTag -ResourceId $rg.ResourceId -Tag $tags -Operation Replace

```

### Build Azure Resource Graph Queries

#### Including Resource Groups

```azurecli
resourcecontainers
| where type == "microsoft.resources/subscriptions/resourcegroups"
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tags[0] =~ 'toBeLocked' and tags[1] =~ 'Yes'
| project  name,type,location,subscriptionId,tags
| union (resources 
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tags[0] =~ 'toBeLocked' and tags[1] =~ 'Yes'
| project name,type,location,subscriptionId,tags,id)
```

#### Excluding Resource Groups

```azurecli
Resources
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tags[0] =~ 'toBeLocked' and tags[1] =~ 'Yes'
```

#### Resource Groups Only

```azurecli
ResourceContainers
| where type =~ 'microsoft.resources/subscriptions/resourcegroups'
| where tags['toBeLocked'] =~ 'Yes'
```

### Getting items from the query programmatically

We now have the required queries and you can pick whichever one above suits your needs, I am going to be using [Including Resource Groups](#including-resource-groups). Now we need a way to act against these resources. I am personally quite a fan of [PowerShell](https://learn.microsoft.com/en-us/powershell/) so I will provide this sample. You can use [this](https://learn.microsoft.com/en-us/azure/governance/resource-graph/first-query-powershell#add-the-resource-graph-module) as a base for my example below. When running the query in [PowerShell](https://learn.microsoft.com/en-us/powershell/), I find [splatting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.2) is easiest for [Azure Resource Graph](https://learn.microsoft.com/en-us/azure/governance/resource-graph/) queries

```powershell
# Install the Resource Graph module from PowerShell Gallery
Install-Module -Name Az.ResourceGraph

# Get a list of commands for the imported Az.ResourceGraph module
Get-Command -Module 'Az.ResourceGraph' -CommandType 'Cmdlet'

# Run Azure Resource Graph query
$query = @"
resourcecontainers
| where type == "microsoft.resources/subscriptions/resourcegroups"
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tags[0] =~ 'toBeLocked' and tags[1] =~ 'Yes'
| project  name,type,location,subscriptionId,tags
| union (resources 
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tags[0] =~ 'toBeLocked' and tags[1] =~ 'Yes'
| project name,type,location,subscriptionId,tags,id)
"@
$queryItems = Search-AzGraph -Query $query
```

### Adding locks

So now we have the items that have been tagged, now we can go through the process of adding a [Resource Lock](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources?tabs=json). The [New-AzResourceLock](https://learn.microsoft.com/en-us/powershell/module/az.resources/new-azresourcelock?view=azps-8.3.0) will be used for this task.

```powershell
$lockLevel = "CanNotDelete" ## can be changed to "ReadOnly" as well
$lockNotes = "Lock for demo blog purposes"
$lockName = "Demo Lock"
foreach ($queryItem in $queryItems)
{
    $name = $queryItem.Name
    $type = $queryItem.Type
    write-host "Locking $name ($type)"
    if ($type -eq "microsoft.resources/subscriptions/resourcegroups"){
        New-AzResourceLock -LockName $lockName -LockLevel $lockLevel -LockNotes $lockNotes -ResourceGroupName $name
    } else {
        $resourceGroupName = ($queryItem.id).split("/")[4]
        New-AzResourceLock -LockLevel $lockLevel -LockNotes $lockNotes -LockName $lockName -ResourceName $queryItem.Name -ResourceType $queryItem.Type -ResourceGroupName $resourceGroupName
    }
}
```

### Results  

Results can be seen below. Our Locks are now in place. Since my account is an **owner**, I can delete the lock(s), *non-owner(s)* would **NOT** be able to delete locks.  

![resulting locks in azure](/blog/assets/cloud/2022/using-arg-tolock-resources/resulting-locks.jpg)

This code and concept can be easily updated or modified to meet different your specific requirements.

