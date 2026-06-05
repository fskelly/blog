---
title: "Using SSH Keys with Bicep based Linux VM templates"
slug: bicep-linux-vm-ssh-keys
description: >-
  I this post, I use bicep files for the deployment of Linux VMs AND I add some magic with PowerSehll to allow for the creation or using of ex...
added: 2022-06-20T08:54:21+01:00
tags:
  - powershell
  - ssh
  - bicep
categories:
  - iac
  - azure
---
I this post, I use bicep files for the deployment of Linux VMs AND I add some magic with PowerSehll to allow for the creation or using of existing SSH keys with these VMs.

I am a HUGE fan of SSH keys with Linux VMs for obvious reasons. I could just not find a script or scenario that covered this topic in a way that I actually like. I like to show more details and explain.

In this scenario, we use PowerShell to create the SSH keys and then use the value to the SSH key to deploy the Linux VM or use an existing SSH key adn then use that kay as part of the deployment. All automated, you just need to update some variables and let the script run. Who does not love automated examples ? :smile:

SSH Keys give us a secure and reliable way to connect to Linux VMs without the use of usernames and passwords. Naturally the keys would need to be protected. Maybe in another post I will create a keyVault to show this process.

Note: Please use 1A OR 1B  
A. Create new keys  
b. Use existing Keys  

## 1A. Create the SSH Keys (if using the option to create keys) [file](https://github.com/fskelly/flkelly-AzureCode-bicep/blob/main/examples/vm/linuxVM/deployWithNewKey.ps1)

Please remember to update the variables as needed.  
Variables to update

1. $vmName
1. **If** you want to change the path of the created keys - $keyLocation

```powershell
## Pre-req

## Create required ssh-keys
## Requires ssh-keygen to be installed

$vmName = ""
$keyLocation  = $env:USERPROFILE + "\.ssh\"
$privateKeyName = $vmName + "-key"
$publicKeyName = $vmName + "-key.pub"
$privateKeyPath = $keyLocation + $privateKeyName
$publicKeyPath  = $keyLocation + $publicKeyName

ssh-keygen -m PEM -t rsa -b 2048 -C $vmName -f $privateKeyPath

##Deploy
$sshKey = Get-Content $publicKeyPath
$secureSSHKey = ConvertTo-SecureString $sshKey -AsPlainText -Force
```

## 1B. Us existing SSH Keys (if using the option to create keys) [file](https://github.com/fskelly/flkelly-AzureCode-bicep/blob/main/examples/vm/linuxVM/deployWithExistingKey.ps1)

```powershell
## Get key data
$publicKeyPath = ""
$sshKey = Get-Content $publicKeyPath
$secureSSHKey = ConvertTo-SecureString $sshKey -AsPlainText -Force

$privateKeyPath = ""
```

## 2. Deploy the Bicep Template [file](https://github.com/fskelly/flkelly-AzureCode-bicep/blob/main/examples/vm/linuxVM/main.bicep)

Please remember to update the variables as needed.  
Variables to update

1. $resourceGroupName
1. $resourceGroupLocation
1. $userName

```powershell
## Deploy to Azure
$resourceGroupName = ""
$resourceGroupLocation = ""
$userName = ""
New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ./main.bicep -adminUsername $userName -adminPasswordOrKey $secureSSHKey

$hostName = (Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName).outputs.hostname.value

## Adding slight delay
Start-Sleep 5

## Connect to the vm
ssh -i $privateKeyPath $userName@$hostName
```

Now you can automatically connect to your newly deployed VM with an SSH Key. How great is that?


