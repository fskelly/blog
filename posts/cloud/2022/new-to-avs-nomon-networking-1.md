---
title: "I want to use Azure VMware Solution, what should I know about networking?"
slug: new-to-avs-nomon-networking-1
description: >-
  What else do I need to know when using Azure VMware Solution (AVS)? Networking Edition I have been working with many customers over the last...
added: 2022-03-09T16:06:00Z
tags:
  - azure
draft: true
---
**What else do I need to know when using Azure VMware Solution (AVS)?**

***Networking Edition***

I have been working with many customers over the last little while that are looking at Azure VMware Solution (AVS).

Often the idea and use case for the customer is correct. There are a few great reasons to use AVS. If you fit within the use cases, you are in for a real treat.

Deciding whether or not you are a fit is part of the equation, there is more to this scenario. Let's dive in a bit more.

1. You are using the Azure platform but on dedicated hardware.
1. You will probably want to extend the connection from AVS to your existing data centre. This will introduce [Global Reach](https://docs.microsoft.com/en-us/azure/azure-vmware/tutorial-expressroute-global-reach-private-cloud) if connecting back to on-premises with an ExpressRoute.
1. You will most likely use [HCX](https://docs.microsoft.com/en-us/azure/azure-vmware/configure-vmware-hcx) as part of your migration.

**So what does all of the above mean?**

Networking can start to get a little interesting as there would now be many routing paths over a combination of Layer 2 and Layer 3 connections.

1. Asymmetric routing can become a real issue.
1. "Accidental" latency can be very easily introduced.
1. Traffic flow may not flow as expected.
1. A PoC (proof of concept) is very important with this technology.
1. Migration planning with network segments in mind is key.
1. Migration should be as "short-term" as possible, the longer the migration takes, the more networking challenges and complexities will arise.

Guidance for networking can be found [here](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/azure-vmware/eslz-network-topology-connectivity)

