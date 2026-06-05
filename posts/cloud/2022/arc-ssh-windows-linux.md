---
title: "Using Arc to SSH into Linux and Windows"
slug: arc-ssh-windows-linux
description: >-
  Using Arc to SSH into Linux and Windows
added: 2022-09-27T08:03:53+01:00
tags:
  - azure
categories:
  - hybrid
  - azure
draft: true
---
## What are we doing?

We are going to use Azure Arc to SSH into a Linux (ubuntu 20.04) and a Windows Server (Server 2019) machine and run commands.

## Constraints / limitations  

1. Use only Azure ARC.  
1. Use only public endpoints (I have not yet tested this with Private Endpoints) and my VPN is not currently connected to Azure.  

## Considerations  

As of the time of this blog post (27-Sep-2022), the [Azure Arc SSH](https://learn.microsoft.com/en-us/azure/azure-arc/servers/ssh-arc-overview) functionality is in preview.

## Lets build this  

So, we are going to use SSH to connect to both Linux and Windows. Yes, you can connect to Windows via SSH and yes it works, we will get this working in this post.

### Steps

1. Install Azure Arc Agent on VMs
1. Ensure that it is connected to Azure Correctly
1. Configurations changes for SSH to work
1. Connect via SSH

I am going to assume that steps 1 and 2 are completed already, if not. See [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/deployment-options). The focus on this post is to connect to your environment using the [azcmagent](https://learn.microsoft.com/en-us/azure/azure-arc/servers/ssh-arc-overview) and then connecting to the virtual machine via the portal.

### Linux VM

![Connect via portal to linux Azure Arc machine](/images/blogImages/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm.png)

You will see that this is a linux vm and SSH working here is no surprise. For this post, I am using password authentication type. **This is not ideal for production**.
![Connect via portal to linux Azure Arc machine options](/images/blogImages/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm-connectoptions.png)
Now you can click, "Connect in browser". This will launch an [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/overview)
![Connect via portal to linux Azure Arc machine button - connect in browser](/images/blogImages/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm-connect-in-browser.png)

## GOTCHA

You may hit your first error here.
![Connect via portal to linux Azure Arc machine button - connection error](/blog/assets/cloud/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm-error-1.png)

The error may seem a little strange, it seems it is using port 66535 to dp a port lookup - like a proxy lookup - see [here](https://serverfault.com/questions/915724/connection-closed-by-unknown-port-65535-when-ssh-using-ad-creds-on-rhel-machine) as an example of this. It is still wanting to connect to port 22, the normal ssh port. _So how do we fix this?_

Configuring the **Az**ure **c**onnected **ma**chine **agent** is documented [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/ssh-arc-overview) and the command we need is this.

```bash
azcmagent config set incomingconnections.ports 22
```

Run this command on your linux machine (sudo will be needed)
![Update port number from azcmagent](/blog/assets/cloud/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm-fix1.png)
and then we can connect  
![Connect via portal to linux Azure Arc machine is successful](/blog/assets/cloud/2022/arc-ssh-windows-linux/connect-button-portal-linux-vm-connect-1.png)

### Windows VM
![Connect via portal to Windows Azure Arc machine](/images/blogImages/2022/arc-ssh-windows-linux/connect-button-portal-windows-vm.png)

The steps for connection from the portal and the required **Az**ure **c**onnected **ma**chine **agent** commands are the same. However we do need to get SSH working on the Windows Server, this is actually quite easy and simply needs some copy and paste, see [here](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell). Once you have done that, your connection will work.

![Connect via portal to Windows Azure Arc machine is successful](/blog/assets/cloud/2022/arc-ssh-windows-linux/connect-button-portal-windows-vm-connect-1.png)

So there you have it, an SSH connection from the Azure portal to a Windows AND Linux Arc-enabled machine.

