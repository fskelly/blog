---
title: "Azure VMware Solution: A comprehensive guide to LDAPS identity integration - Part 3"
slug: avs-ldaps-configure-part3
description: >-
  Author(s): Robin Heringa and Fletcher Kelly Implementing LDAPS identity integration with Azure VMware Solution series 3 of 4 This is the thi...
added: 2023-01-25T08:45:43Z
tags:
  - avs
  - identity
  - ldaps
draft: true
---
Author(s): [Robin Heringa](/about/robinheringa/) and [Fletcher Kelly](/about/fletcherkelly/) 

# Implementing LDAPS identity integration with Azure VMware Solution series - 3 of 4 #

This is the third part of the blog series on how to implement LDAPS identity integration with Azure VMware Solution. Other parts of this series can be found here: 

1. [LDAPS integration - part 1 of 4](../avs-ldaps-configure-part1/)
1. [LDAPS integration - part 2 of 4](../avs-ldaps-configure-part2/)
1. [LDAPS integration - part 4 of 4](../avs-ldaps-configure-part4/)

# Implement LDAPS integration #

The following sections will guide you through the required process step-by-step

## Check domain controller certificates and LDAPS ##

It is important to validate that the identity provider (in most cases Active Directory) is configured to support LDAPS based authentication requests before continuing with the LDAPS integration setup.  

For each domain controller that is designated for use with Azure VMware Solution, check if the required certificate(s) with the "server authentication" intended purpose are present in the computer certificate store. The "Certificates" snap-in for the Microsoft Management Console (mmc.exe) offers a simple way to do this.  

After locally or remotely opening the computer certificate store:

1. Expand the "Personal" certificate store and click "Certificates";
1. Check if the store contains certificates with the "Server Authentication" intended purpose.

Available certificates for **avs-gwc-dc001.avsemea.com**:
![avs-gwc-dc001-certificates mmc](/blog/assets/cloud/2023/avs-ldaps-configure-part3/1-avs-gwc-dc001-certificates.jpg)

Available certificates for **avs-gwc-dc002.avsemea.com**:
![avs-gwc-dc002-certificates mmc](/blog/assets/cloud/2023/avs-ldaps-configure-part3/2-avs-gwc-dc002-certificates.jpg)

Next we need to verify whether the Active Directory domain controllers are configured to offer LDAPS services:  

1. Open a "Command prompt" windows;
1. Run the command "Netstat -a";
1. Verify that there is an active listener for TCP port 636.

LDAPS listener for **avs-gwc-dc001.avsemea.com**:
![avs-gwc-dc001-netstat-results](/blog/assets/cloud/2023/avs-ldaps-configure-part3/3-avs-gwc-dc001-netstat.jpg)

LDAPS listener for **avs-gwc-dc002.avsemea.com**:
![avs-gwc-dc002-netstat-results](/blog/assets/cloud/2023/avs-ldaps-configure-part3/4-avs-gwc-dc002-netstat.jpg)

## Extract (correct) domain controller certificates

As a next step the certificates used by the domain controllers for LDAPS services need to be extracted from the domain controllers. This step is always performed by executing the script shown in the image below. The reason for this is to ensure we extract the correct certificate which is "attached" to the LDAPS service. When multiple certificates are available with the "Server Authentication" intended purpose, the domain controller selects one of them to be used for LDAPS.  

With the following commands we will connect to the required domain controllers. In our scenario, these are **avs-gwc-dc001.avsemea.com** and **avs-gwc-dc002.avsemea.com** and we then use OpenSSL to extract the required certificates. You will need to specify the path of your openssl.exe, currently tested version is 3.0 and was installed with [Chocolatey](https://community.chocolatey.org/packages/openssl). Our install path is **C:\Program Files\OpenSSL-Win64\bin\openssl.exe**. You will need to update the export path to suit your needs, we chose to use **c:\certTemp**

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

![PowerShell-using-openssl-to-extract-certs](/blog/assets/cloud/2023/avs-ldaps-configure-part3/5-powershell-cert-extract.jpg)

## Validate domain controller certificate requirements

The next step is to ensure that the certificate extraction was performed successfully. This will always be a manual step in the process.

![Exported-certificate-properties](/blog/assets/cloud/2023/avs-ldaps-configure-part3/6-certificate-properties.jpg)

As displayed in the image above:

1. Open Windows Explorer (or use the one opened in the previous step if not closed already 😊) and browse to the location where the certificates were extracted to. In our scenario the folder is c:\certTemp;
2. Open the certificates by right-clicking and selecting "Open"

For each of the certificates:  

3. Select the "General" tab at the top;  
4. Verify that "Proves your identity to a remote computer" is available as an intended purpose;
5. Verify that domain controller fully qualified domain name FQDN) is present in the "Issued to" field. In our scenario: **avs-gwc-dc001.avsemea.com** and **avs-gwc-dc002.avsemea.com**.
6. Verify that the certificate is still valid by checking the "Valid from" field.

![Certification-path-of-the-certificate](/blog/assets/cloud/2023/avs-ldaps-configure-part3/7-certificate-certification-path.jpg)

To complete the certificate verification process, for each certificate:

1. Click the "Certification Path" tab at the top;
1. Verify that the full certificate authority chain is available in the "Certification path" field.
In our scenario the field contains the name of the root certification authority **avsemea-avs-gwc-rootca** and the full certificate name for the respective domain controller the certificate is issued to. In our scenario **avs-gwc-dc001.avsemea.com** and **avs-gwc-dc002.avsemea.com**.

## Create Azure Storage account

The following content is divided into two sub-sections. One section will describe how the required procedure is performed manually through the Azure Portal and the other section describes a way to perform the required steps through automation.

### Manual deployment

As part of this manual process a storage account will be created that is used to store the domain controller certificates for later use by the "New-LDAPSIdentitySource" run-command.

![create-storage-account-from-portal](/blog/assets/cloud/2023/avs-ldaps-configure-part3/8-manual-storage-account-create.jpg)

In the Azure Portal:

1. Click on "Storage accounts" in the left navigation panel;
1. Click "+ Create" at the top to create a new storage account. The "Create a storage account" blade will now be displayed.

![create-storage-account-from-portal-storage-account-information](/blog/assets/cloud/2023/avs-ldaps-configure-part3/9-manual-storage-account-create-2.jpg)

On the "basics" tab:

1. In the "Subscription" drop-down menu make sure you select the subscription where Azure VMware Solution has been deployed into. In our scenario this is the **Azure CXP FTA Internal – AZFTA subscription**;
1. Select the resource group you want to create the storage account into. In our case **avs-germanywestcentral-operational_rg**.
1. In the "Storage account name" box, enter a globally unique name for the storage account. We recommend to use a descriptive name postfixed with a GUID. In our scenario we used **avsgwcsa14a2c2db**;
1. In the "Region" drop-down menu be sure to select the same region as where Azure VMware Solution is deployed. In our scenario **Germany West Central**.
1. As this storage account has no need for changing any of the default settings, click "Review" at the bottom of the screen.

![create-storage-account-from-portal-storage-account-review](/blog/assets/cloud/2023/avs-ldaps-configure-part3/10-manual-storage-account-review.jpg)

On the review screen:

1. Double-check the values for "Subscription", "Resource Group", "Location" and "Storage account name";
1. Click "Create".
After a few minutes the creation of the storage account should be completed:

![create-storage-account-from-portal-storage-account-review-complete](/blog/assets/cloud/2023/avs-ldaps-configure-part3/11-manual-storage-account-review-2.jpg)  

### Automated deployment

With these commands, we will check for the Azure Module, install them if missing and then continue the script. We will create the required storage account, or use an existing storage account. The **$storageAccountName**  and **$resourceGroupLocation** variables can be updated or replaced as needed to meet your needs. These scripts are designed to be run in sections one after each other to ensure the variable names are correctly referenced.

**Notes**  
***$resourceGroupLocation*** will need to be updated to your desired location.  
***$storageRgName*** will need to be updated.  
***$storageAccountName*** will need to be updated.  

```powershell
## Do you have the Azure Module installed?
if (Get-Module -ListAvailable -Name Az.Storage)
    { write-output "Module exists" }        
else 
    {
    write-output "Module does not exist"
    write-output "installing Module"
    Install-Module -name Az.Storage -Scope CurrentUser -Force -AllowClobber
    }

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

![scripted-creation-of-storage-account](/blog/assets/cloud/2023/avs-ldaps-configure-part3/12-automated-create-storage-account.jpg)  

## Create Storage Blob container

The next step is to create a blob container to help structure/organize the resources required for the LDAPS identity integration.
The following content is divided into two sub-sections. One section will describe how the required procedure is performed manually through the Azure Portal and the other section describes a way to perform the required steps through automation.

### Manual deployment

![create-storage-container](/blog/assets/cloud/2023/avs-ldaps-configure-part3/13-manual-create-container.jpg)  

In the Azure Portal:

1. In the left navigation pane, click "Storage accounts";
1. In the list of storage accounts, select the storage account created in the previous step. In our scenario **avsgwcsa14a2c2db**;
1. Select "Containers" under the "Data storage" category;
1. Click "+ Container" to create a new container in the storage account.

![create-storage-container-final](/images/blogImages/2023/avs-ldaps-configure-part3/14-manual-create-container-2.jpg)  

In the "New container" dialog:

1. In the "Name" field, type a descriptive name for the new container. In our scenario **ldaps-blog-post**.
1. Click "Create"
The new container should now be created and displayed in the "Containers" view for the storage account:

### Automated deployment

With these commands, we will create the container to upload the earlier exported certificates to, this will be important for the creation of the SAS Tokens for the AVS LDAPS Run Command.

**Notes**  
***$containerName*** will need to be updated

```powershell
## create container
$containerName = "ldaps-blog-post"
$containerCheck = Get-AzStorageContainer -name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName).Context -ErrorAction SilentlyContinue
if ($null -eq $containerCheck)
{
    New-AzStorageContainer -name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $storageRgName -Name $storageAccountName).Context
    Write-Output "Storage container created: $containerName"
} else {
    write-output "Container already exists"
}
```

![create-storage-container](/blog/assets/cloud/2023/avs-ldaps-configure-part3/15-automated-create-storage-container.jpg)  

## Upload domain controller certificates

The next step is to upload the domain controller certificates from the temporary folder where they were extracted to into the newly created **ldaps-blog-post** container in the **avsgwcsa14a2c2db** storage account we created.
The following content is also divided into two sub-sections. One section will describe how the required procedure is performed manually through the Azure Portal and the other section describes a way to perform the required steps through automation.

### Manual deployment

As the first step, it is needed to "enter" the **ldaps-blog-post** container in the storage account:

![start-of-cert-upload-process](/blog/assets/cloud/2023/avs-ldaps-configure-part3/16-manual-upload-certs-1.jpg)  

1. In the Azure Portal, navigate to the **avsgwcsa14a2c2db** storage account created earlier and select "Containers";
1. Click the **ldaps-blog-post** container.

We will now upload the certificates into the container:

![start-of-cert-upload-process-1](/blog/assets/cloud/2023/avs-ldaps-configure-part3/17-manual-upload-certs-2.jpg)  

1. In the **ldaps-blog-post** container, select "Overview";
1. In the top navigation, click "⬆️ Upload";
1. In the "Upload blob" panel, click the folder icon to select the certificates from your local hard drive.

![start-of-cert-upload-process-3](/blog/assets/cloud/2023/avs-ldaps-configure-part3/18-manual-upload-certs-3.jpg)  

Navigate to the folder where the certificates have been extracted to (in our scenario c:\certTemp) and:

1. Select all the certificates;
1. Click "Open".

The "Open" screen will close and return to the Azure Portal "Upload blob" panel again, click "Upload" at the bottom of the screen:

![upload-certs-4](/images/blogImages/2023/avs-ldaps-configure-part3/19-manual-upload-certs-4.jpg)  

The certificates will now be uploaded into the blob container. The process is complete when green checkmarks are shown for each certificate uploaded:

![upload-certs-complete](/images/blogImages/2023/avs-ldaps-configure-part3/20-manual-upload-certs-complete.jpg) 

### Automated deployment

With these commands, we will upload the actual certificates into the previously created container. In this example we are using "**ldaps-blog-post**"

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

![scripted-cert-upload-1](/blog/assets/cloud/2023/avs-ldaps-configure-part3/21-automated-upload-certs-1.jpg) 

![scripted-cert-upload-2](/blog/assets/cloud/2023/avs-ldaps-configure-part3/22-automated-upload-certs-2.jpg) 

## Generate SAS tokens for domain controller certificates

As part of this step we will generate "shared access tokens" for all the certificates uploaded into the blob container so they can be accessed through the run-command for implementing the LDAPS integration for vCenter.
One section describes how the required procedure is performed manually through the Azure Portal and the other section describes a way to perform the required steps through automation.

### Manual deployment

The manual deployment continues within the same blade in the Azure Portal where the previous step left off.
For each of the uploaded certificates, generate a "**SAS token**":

![sas-process-1](/images/blogImages/2023/avs-ldaps-configure-part3/23-manual-generate-sas-1.jpg) 

For each certificate separately:

1. Select the checkbox in front of the container;
1. Click the ellipsis at the end of the line;
1. Select "Generate SAS".

In the following screen:

![sas-process-2](/images/blogImages/2023/avs-ldaps-configure-part3/24-manual-generate-sas-2.jpg) 

1. Make sure to select a proper validity period for the SAS token. By default the SAS token will be valid for 8 hours which should be sufficient when performing the configuration in a continuous effort;
1. Click "Generate SAS token and URL".
After clicking "Generate SAS token and URL" an additional section will be displayed at the bottom of the screen:

![sas-process-complete](/images/blogImages/2023/avs-ldaps-configure-part3/25-manual-generate-sas-complete.jpg) 

Be sure to copy the "Blob SAS URL" generated for each separate certificate into a text-file temporarily as they will need to be concatenated into a single string **separated by a comma** for use during the execution of the run-command as explained in step "Execute Run-Command".

### Automated deployment

With these commands, we will generate the SAS Token needed for the next steps, please note down **BOTH** tokens. In this script, the tokens are valid for **24 hours** and can be modified to suit your needs.

**Notes**  
***$containerName*** will need to be updated

```powershell
## create SAS token
$containerName = "ldaps-blog-post"
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

![scripted=sas-token-creation](/blog/assets/cloud/2023/avs-ldaps-configure-part3/26-automated-sas-token-creation.jpg) 

[snippets.ps1 file (all code commands)](https://github.com/fskelly/flkelly-cloudblog/blob/main/content/post/2023/avs-ldaps-configure-part1/snippets.ps1)  
[< Previous](../avs-ldaps-configure-part2/) [Next>](../avs-ldaps-configure-part4/)

