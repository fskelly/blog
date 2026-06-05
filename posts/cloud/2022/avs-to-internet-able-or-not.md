---
title: "Azure VMware Solution: To 'Internet Enabled' or not?"
slug: avs-to-internet-able-or-not
description: >-
  Guest Post Author: Robin Heringa What else do I need to know when using Azure VMware Solution (AVS)? As you all (probably) know by now Azure...
added: 2022-03-17T16:06:00Z
tags:
  - azure
draft: true
---
**Guest Post**
Author: [Robin Heringa](/about/robinheringa/)  

**What else do I need to know when using Azure VMware Solution (AVS)?**

As you all (probably) know by now Azure VMware Solution is a managed service offered by Microsoft providing a managed VMware vSphere environment to customers. With this offering customers no longer need to worry about hardware maintenance, hardware refresh and software maintenance for the core VMware components (ESXi, vCenter and NSX-T).

By default, after initial deployment of Azure VMware Solution, virtual machines do not have the ability to egress to the Internet. One of the options to enable Internet access is to "flip" the "Internet Enabled" toggle in the connectivity pane of the management blades in the Azure Portal:

![internet enabled switch](/blog/assets/cloud/2022/avs-to-internet-able-or-not/AVS-Connectivity-Settings-InternetEnabled.jpg)

Looks easy, but what does it do?

**Internet Enabled option in Azure VMware Solution.**

Microsoft runs an Internet break-out capability for Azure VMware Solution which is shared across the customers using Azure VMware Solution. When enabling this capability, a default networking route (0.0.0.0/0) is injected into to Azure VMware Solution Private Cloud which points "unknown destinations" to the shared break-out infrastructure.

While this capability offers a secure connectivity option to the Internet, it does not offer capabilities for traffic inspection and filtering and thus doesn't allow for monitoring what traffic is leaving the environment.

While "Internet Enabled" offers a great way to quickly enable virtual machines on Azure VMware Solution to connect to the Internet, it is maybe not the best option to use for production deployments.

**What should I do for production workloads?**

For (large) production deployments, it is recommended to use Border Gateway Protocol (BGP) to inject a default route (0.0.0.0/0) which defines a customer controlled internet egress point (aka. firewall) as the next hop address. This approach will allow for inspection and filtering to be performed on traffic leaving and entering Azure VMware Solution hosted workloads.

There are various options to implement such an infrastructure.
For more information on using Azure Virtual WAN for this scenario, see [Enable public internet for Azure VMware Solution workloads](https://docs.microsoft.com/en-us/azure/azure-vmware/enable-public-internet-access).

Next to this, it is of course also possible to either "inject" the default route from the customer on-premises infrastructure (in which case on-premises and Azure will probably share the same Internet break-out point) or it is possible to implement network virtual appliances (NVA) from our networking partners (Fortigate, Palo Alto, Baracuda and many others) to inject an Azure specific default route and attract the traffic destined for the internet. We will go deeper into using third party solutions in later articles.

