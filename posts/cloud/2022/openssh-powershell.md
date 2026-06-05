---
title: "Using Openssh and creating SSH Keys with Powershell"
slug: openssh-powershell
description: >-
  In this post I show you my process for creating SSH Keys for Linux Machines. I use a fair amount of Linux in my work career (creating VMs an...
added: 2022-04-25T14:27:03+01:00
tags:
  - powershell
  - ssh
---
In this post I show you my process for creating SSH Keys for Linux Machines.

I use a fair amount of Linux in my work career (creating VMs and the like within Azure). Linux VMs are great for testing with, they use SSH and are configured and ready for testing VERY quickly in Azure. I also use a fair amount of Linux in personal life, with [Home assistant](https://home-assisant.io) and [Plex](https://plex.tv).

I know many people use username and password with Linux environments and there is nothing wrong with this, I simply think that keys are better :smile: . I believe this for a few reasons.

1. Allows for better control over access to a machine - no key, no access.
1. Allows for a better logon experience, seems more "seamless"
1. Key information can be stored in a secure location for repeated use
    1. For personal use, I store the key information in [1Password](https://1password.com/)
    1. For work use, I store the key information in Azure Kayvault
1. Can be easily scripted to create new keys as needed

With the last point, I am a big [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7.2) user and I have created a simple script that work in [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7.2) and [PowerShell Core](https://github.com/powershell/powershell).

You will need openssh for this to work. The command below will help with this 👍.

```powershell
choco install openssh
```

Now for the PowerShell code, update the variables as needed. This creates the keys for us.

```powershell
$username = ""
$keyLocation = ''
$keyName = $username
$keyPath = $keyLocation + $keyName
ssh-keygen -m PEM -t rsa -b 4096 -f $keyPath -C $username
```

Now to get the content of the public key, for use with Azure VMs or any type of IaC, I use [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep)

You can read the content out to something simple like NotePad (Honestly a tool I use **DAILY**).

```powershell
$pubKeyPath = $keyPath + '.pub'
$pubKey = get-content -Path $pubKeyPath
$pubKey
```

Example output from $pubkey below, this is what you need to copy and paste within the Azure Portal when creating a Linux VM.

![ssh-key-example](/blog/assets/cloud/2022/openssh-powershell/ssh-key-example.jpg)

If you want to use this key with an existing, you can. :smile: . We can perform a task similar to ssh-copy-id. Update the ***$destinationIp*** as needed.

```powershell
$destinationIp = ""
type $pubKeyPath | ssh $username@$destinationIp "cat >> .ssh/authorized_keys"
```


