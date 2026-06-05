---
title: "Azure VMware Solution: A comprehensive guide to LDAPS identity integration - Part 1"
slug: avs-ldaps-configure-part1
description: >-
  Author(s): Robin Heringa and Fletcher Kelly Implementing LDAPS identity integration with Azure VMware Solution series 1 of 4 This is the fir...
added: 2023-01-25T08:45:43Z
tags:
  - avs
  - identity
  - ldaps
---
Author(s): [Robin Heringa](/about/robinheringa/) and [Fletcher Kelly](/about/fletcherkelly/) 

# Implementing LDAPS identity integration with Azure VMware Solution series - 1 of 4 #

This is the first part of the blog series on how to implement LDAPS identity integration with Azure VMware Solution. Other parts of this series can be found here:

1. [LDAPS integration - part 2 of 4](../avs-ldaps-configure-part2/)
2. [LDAPS integration - part 3 of 4](../avs-ldaps-configure-part3/)
3. [LDAPS integration - part 4 of 4](../avs-ldaps-configure-part4/)

Azure VMware Solution (AVS) offers a fully managed software defined data center based on VMware vSphere technologies in the shape of an Azure PaaS service. The PaaS nature of Azure VMware Solution results in a service that is functionally equivalent to your well-known on-premises VMware deployment you may have been using for years with some specific “restrictions” as Microsoft provides a service level agreement and therefor Microsoft is responsible for ensuring a robust and resilient platform in deployment and operation.  Azure VMware Solution is functionally equivalent to on-premises VMware but due to the PaaS nature of the service there are significant technical differences to properly consider.

## Run-Commands for high(er) privileged operations ##

As a consumer of Azure VMware Solution, you are granted limited administrative privileges that are aligned with the PaaS nature of the service. You are granted access to the CloudAdmin role which holds a subset of the full administrator role. As it is at times needed to allow for “privilege escalation”, Microsoft has enabled you to do so using a feature in the Azure AVS portal blades called “Run-Commands”. Run-Commands allow you to perform a selected number of high privileged actions without requiring the need to submit a service request through Azure Support from the Azure Portal. More details on Run-Commands can be found on Microsoft Learn [here](https://learn.microsoft.com/en-us/azure/azure-vmware/concepts-run-command).

To integrate your Azure VMware Solution SDDC with a directory services provider, in our case Active Directory, we will use a Run-Command: New-LDAPSIdentitySource.

## Our Azure VMware Solution lab environment ##

To allow us to create this article using “understandable” values for the prerequisites and the parameters required to successfully implement the LDAPS identity integration, we have created a lab environment which is shown in the picture below. Using this picture as a reference we hope to make it easier for anyone to implement LDAPS integration by simply replacing the prerequisite values and parameters (displayed in bold through-out this document) with the values applicable to your environment by simply comparing with our lab and easily translating this to what is applicable for your deployment.

Our lab consists of:

| Required resources:          | |
| ----------- | :----------- |
| One Azure VMware Solution Private Cloud called | **avs-fta-gwc** |
| One Active Directory forest and domain called | **avsemea.com** | 
| Two Active Directory domain controllers called | **avs-gwc-dc001** and **avs-gwc-dc002** |
| One Active Directory hosted enterprise root certificate authority called | **avsemea-avs-gwc-rootca** |
| One Azure Virtual WAN called |**avs-germanywestcentral-vwan1** |
| One jumpbox virtual machine used for management activities called |**avs-gwc-jumpbox** |
| One Azure Virtual Network called |**avs-gwc-172_16_11_0-24** |
| This vnet holds three separate subnets called | **SN-172_16_11_0-26-ADDS**, **AzureBastionSubnet** and **SN-172_16_11_128-26** |

All virtual machines used in the lab are joined to the above mentioned avsemea.com domain
Our lab environment also holds some additional resources that are not required for the LDAPS integration but they will be used when creating additional articles on different Azure VMware related topics just like this one.

| Optional resources for future use: ||
| ----------- | :----------- |
| Two NSX-T segments inside our AVS SDDC called | **NSX-SN-192-168-200-0-24** and **NSX-SN-192-168-201-0-24** |
| One virtual machine for forwarding additional metrics from our AVS SDDC to the Azure Metrics infrastructure called |**avs-gwc-metrics001** |
| One Azure NetAppFiles account that will be used as extensible storage for our AVS SDDC in a later article called | **avs-gwc-anfaccount001** |

A graphical representation of our lab environment is shown below:

![FTA Lab Environment](/blog/assets/cloud/2023/avs-ldaps-configure-part1/FTA-lab-environment.jpg)

While guiding you through the process of gathering all required details and artifacts and using them to complete the LDAPS integration for AVS, we assume that you have all resources mentioned in the table required resources available and that sufficient access permissions are in place.

[snippets.ps1 file (all code commands)](https://github.com/fskelly/flkelly-cloudblog/blob/main/content/post/2023/avs-ldaps-configure-part1/snippets.ps1)  
[Next>](../avs-ldaps-configure-part2/)


