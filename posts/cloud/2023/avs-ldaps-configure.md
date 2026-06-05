---
title: "How to configure LDAPS with AVS"
slug: avs-ldaps-configure
description: >-
  In this post, we are going to be configuring LDAPS (LDAP Over SSL) for Azure Vmware Solution (AVS). Pre requisites 1. Jump Box 1. RSAT Tools...
added: 2023-01-09T08:39:32Z
tags:
  - azure
draft: true
---
In this post, we are going to be configuring LDAPS (LDAP Over SSL) for Azure Vmware Solution (AVS).

Pre-requisites

1. Jump Box
1. RSAT Tools
1. PowerShell installed

The expected outcome

- [Variables we used and information you need](#variables-we-used-and-information-you-need)
- [1. Log into Azure](#1-log-into-azure)
- [2. Export required certificates](#2-export-required-certificates)
- [3. Create a storage account](#3-create-a-storage-account)
- [4. Create a container](#4-create-a-container)
- [5. Upload certificates to container](#5-upload-certificates-to-container)
- [6. Create the SAS Tokens](#6-create-the-sas-tokens)
- [Execute the AVS Run Command](#execute-the-avs-run-command)

The plan is to automate as much of this process as possible. We will use PowerShell to complete steps 1-6 as above. For now, step 7 needs to be manual, we are working on automating this as well.

## Variables we used and information you need

We use the following.  
DNS Name = avsemea.com  
Netbios Name = AVSEMEA  
You will see that we use the Fully Qualified domain names later with the computer names we reference later. We use FQDN as much as possible and try to hard code as little making these snippets more portable into your environment(s).  

We are using a jump-box, which is domain joined, deployed into Azure and protected with [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview). THe snippets below are run on this jump-box, which has [RSAT](https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/remote-server-administration-tools) installed.

## 1. Log into Azure

Update the variables as needed, in this case, ***$azSubscriptionID***

**Notes**  
***$azSubscriptionID*** would need to be updated with your Subscription ID.

```powershell
$azSubscriptionID = ""
Login-AzAccount
Set-AzContext -Subscription $azSubscriptionID
```

## 2. Export required certificates

You will need to have OpenSSL installed. You can do this manually, or use a package manager like [winget](https://winget.run/pkg/ShiningLight/OpenSSL) or
[chocolatey](https://community.chocolatey.org/packages/openssl)

**Notes**  
***$openSSLFilePath*** may need to be changed, was installed using [chocolatey](https://community.chocolatey.org/packages/openssl) in our example.  
***$remoteComputers*** would need to be changed to suit your environment.  
***$exportFolder*** can be changed to something more suitable for your environment.

```powershell
## Get certs
$openSSLFilePath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
$remoteComputers = "avs-gwc-dc001.avsemea.com","avs-gwc-dc002.avsemea.com"
$port = "636"
$exportFolder = "c:\temp\"

foreach ($computer in $remoteComputers)
{
    $output =  echo "1" | & $openSSLFilePath "s_client" "-connect" "$computer`:$port" "-showcerts" | out-string
    $Matches = $null
    $cn = $output -match "0 s\:CN = (?<cn>.*?)\r\n"
    $cn = $Matches.cn
    $Matches = $null
    $certs = select-string -inputobject $output -pattern "(?s)(?<cert>-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)" -allmatches
    $cert = $certs.matches[0]
    $exportPath = $exportFolder+($computer.split(".")[0])+".cer"
    $cert.Value | Out-File $exportPath -Encoding ascii
}
```

You can see the exported files in the picture below.

![code-snippet-1](/blog/assets/cloud/2023/avs-ldaps-configure/snippet1.jpg)

## 3. Create a storage account

**Notes**  
***$resourceGroupLocation*** will need to be updated to your desired location.  
***$storageRgName*** will need to be updated.  
***$storageAccountName*** will need to be updated.  

```powershell
## create storage account

$resourceGroupLocation = "germanywestcentral"
$storageRgName = "avs-$resourceGroupLocation-operational_rg"
## Storage account variables
$guid = New-Guid
$storageAccountName = "avsgwcsa"
$storageAccountNameSuffix = $guid.ToString().Split("-")[0]
$storageAccountName = (($storageAccountName.replace("-",""))+$storageAccountNameSuffix )
## Define tags to be used if needed
## tags can be modified to suit your needs, another example below.
#$tags = @{"Environment"="Development";"Owner"="FTA";"CostCenter"="123456"}
$tags = @{"deploymentMethod"="PowerShell"; "Technology"="AVS"}
## create storage account
$saCheck = Get-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName -ErrorAction SilentlyContinue
if ($null -eq $saCheck)
{
    New-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName -Location $resourceGroupLocation -SkuName Standard_LRS -Kind StorageV2 -EnableHttpsTrafficOnly $true -Tags $tags
    Write-Output "Storage account created: $storageAccountName"
} else {
    write-output "Storage Account already exists"
}
```

![code-snippet-2](/blog/assets/cloud/2023/avs-ldaps-configure/snippet2.jpg)

## 4. Create a container

**Notes**  
***$containerName*** will need to be updated

```powershell
## create container
$containerName = "ldaps"
$containerCheck = Get-AzStorageContainer -name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName).Context -ErrorAction SilentlyContinue
if ($null -eq $containerCheck)
{
    New-AzStorageContainer -name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName).Context
    Write-Output "Storage container created: $containerName"
} else {
    write-output "Container already exists"
}
```

![code-snippet-3](/blog/assets/cloud/2023/avs-ldaps-configure/snippet3.jpg)

## 5. Upload certificates to container

```powershell
## upload certs to container
$certs = Get-ChildItem -Path $exportFolder -Filter *.cer
$storageContext = (Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $storageRgName).Context
foreach ($item in $certs)
{
    $localFilePath = $item.FullName
    $azureFileName = $localFilePath.Split('\')[$localFilePath.Split('\').count-1]
    Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $storageRgName | Get-AzStorageContainer -Name $containerName | Set-AzStorageBlobContent -File $localFilePath -Blob $azureFileName
}
```

![code-snippet-5](/blog/assets/cloud/2023/avs-ldaps-configure/snippet5.jpg)

## 6. Create the SAS Tokens

**Notes**  
***$containerName*** will need to be updated

```powershell
## create SAS token
$containerName = "ldaps"
$blobs = Get-AzStorageBlob -Container $containerName -Context $storageContext | Where-Object {$_.name -match ".cer"}
foreach ($blob in $blobs)
{
    $StartTime = Get-Date
    $EndTime = $startTime.AddHours(24.0)
    $sasToken = New-AzStorageBlobSASToken -Container $containerName -Blob $blob.name -Permission rwd -StartTime $StartTime -ExpiryTime $EndTime -Context $storageContext -FullUri
    #$sasToken
    write-host "SASToken created: $sasToken"
}
```

![code-snippet-5](/blog/assets/cloud/2023/avs-ldaps-configure/snippet5.jpg)

SASToken created: https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc001.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed]  
SASToken created: https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc002.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed] 

## Execute the AVS Run Command  

These steps, for now, are run manually from the [Azure Portal](https://portal.azure.com). This will be found "Azure VMware Solution" and under Operations, **Run command**. Then select **"New-LDAPSIdentitySource"**

![code-snippet-7](/blog/assets/cloud/2023/avs-ldaps-configure/snippet7.jpg)  

Populate the information as needed.  
**Note: the SSLCertificateSasUrl is a single string consisting of the SASTokens separated with a “,”. For example, https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc001.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed], https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc002.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed] and pasted as a single long string.**
The other values would need to be updated as per your environment.  
**Note: With the BaseDNGroups and BaseDNUsers, watch the values used as these should be under the same tree, in this example, “OU=Corp,DC=avsemea,DC=com”**

![code-snippet-8](/blog/assets/cloud/2023/avs-ldaps-configure/snippet8.jpg)  

Once all information is entered, Run the command.

![code-snippet-9](/blog/assets/cloud/2023/avs-ldaps-configure/snippet9.jpg)  

You can check the status of the **Run command** within the portal, under Operations, **Run command**, then select **Run execution status** and then select the correct job.

![code-snippet-10](/blog/assets/cloud/2023/avs-ldaps-configure/snippet10.jpg)  

You can check the status of the job now and you are waiting for all the tasks to be completed and show that your selected group was added to **CloudAdmins**

![code-snippet-11](/blog/assets/cloud/2023/avs-ldaps-configure/snippet11.jpg)  

You can also check the output and ensure that the correct name was added.  

![code-snippet-12](/blog/assets/cloud/2023/avs-ldaps-configure/snippet12.jpg)  

You can logon with LDAP based credentials.
![code-snippet-13](/blog/assets/cloud/2023/avs-ldaps-configure/snippet13.jpg) 
![code-snippet-14](/blog/assets/cloud/2023/avs-ldaps-configure/snippet14.jpg)

