---
title: "Azure VMware Solution: A comprehensive guide to LDAPS identity integration - Part 2"
slug: avs-ldaps-configure-part2
description: >-
  Author(s): Robin Heringa and Fletcher Kelly Implementing LDAPS identity integration with Azure VMware Solution series 2 of 4 This is the sec...
added: 2023-01-25T08:45:43Z
tags:
  - avs
  - identity
  - ldaps
---
Author(s): [Robin Heringa](/about/robinheringa/) and [Fletcher Kelly](/about/fletcherkelly/) 

# Implementing LDAPS identity integration with Azure VMware Solution series - 2 of 4 #

This is the second part of the blog series on how to implement LDAPS identity integration with Azure VMware Solution. Other parts of this series can be found here:

1. [LDAPS integration - part 1 of 4](../avs-ldaps-configure-part1/)
1. [LDAPS integration - part 3 of 4](../avs-ldaps-configure-part3/)
1. [LDAPS integration - part 4 of 4](../avs-ldaps-configure-part4/)

## Configure DNS forwarding prerequisite ##

Before we can configure integration with an external identity store (e.g. Active Directory Domain Services) we need to make sure that the AVS platform components have the ability to resolve customer DNS zones hosting the LDAPS domain records. This configuration must be made through the Azure Portal blades for Azure VMware Solution.

## Open the Azure VMware Solution DNS configuration pane ##

The first step in configuring DNS name resolution from the Azure VMware Solution networks (management and workload segments) is to add a DNS zone for Azure VMware.
Login to the Azure Portal and select the Azure Active Directory tenant and Azure subscription where you have deployed your Azure VMware Solution Private Cloud.

![Open DNS Configuration](/blog/assets/cloud/2023/avs-ldaps-configure-part2/open-DNS-configuration-pane.jpg)

As depicted in the image above:

1. Click on "Azure VMware Solution" in the main navigation pane;
1. Click the Azure VMware Solution Private Cloud you want to configure. In our scenario walk-through we select **avs-fta-gwc** as per the description of our lab environment used;
1. In the navigation pane that now opened, scroll down to the section "Workload networking" and select "DNS".
The Azure Portal blade for configuring the Azure VMware Solution DNS configuration will now open.

## Configure the required DNS zones details ##

The Azure VMware Solution DNS configuration pane opens the section where "conditional DNS forwarder" zones are configured.

![Advanced DNS Configuration](/blog/assets/cloud/2023/avs-ldaps-configure-part2/configure-the-required-DNS-zones-details-1.jpg)

As shown in the image above:

1. Click "+ Add" in the top navigation structure. A new configuration panel will appear on the right side of your browser window;
1. Under (DNS zone) Type, select the "FQDN zone" option;
1. Under DNS zone name, enter a descriptive name used within NSX-T to identify the DNS zone. We recommend to use the DNS FQDN of the zone used by your LDAP/S identity infrastructure. In our scenario the DNS zone name we use is **avsemea.com**;
1. Under Domain, enter the DNS zone FQDN we will be forwarding traffic for. In our scenario we use **avsemea.com** here as well;
1. Under DNS server IP, enter the IP addresses of your DNS servers. It is recommended to use DNS servers that are situated inside of Azure. In our scenario we will use the IP addresses of our two avsemea.com domain controllers: **172.16.11.4** and **172.16.11.5**;
1. Click the "OK" button to create the required DNS FQDN zone in NSX-T.

After a few minutes, the DNS FQDN zone, **avsemea.com**, will be listed in the DNS blade for your Azure VMware Solution Private Cloud as shown below:

![Advanced DNS Configuration 2](/blog/assets/cloud/2023/avs-ldaps-configure-part2/configure-the-required-DNS-zones-details-2.jpg)

## Attach the DNS zone configuration to the NSX-T DNS forwarder service ##

Now that we created the DNS conditional forwarder zone we need to attach this zone to the NSX-T DNS service running in Azure VMware Solution to enable NSX-T to actually use the DNS conditional forwarder zone for use.

![DNS and NSX-T Forwarder](/blog/assets/cloud/2023/avs-ldaps-configure-part2/Attach-the-DNS-zone-configuration-to-the-NSX-T-DNS-forwarder-service-1.jpg)

In the Azure VMware Solution DNS blade:

1. Click "DNS service" at the top of the blade;
1. Click "Edit" to enable configuration changes to the NSX-T DNS service;
1. In the "Edit DNS service" screen, open the "FQDN zones" drop down and select the FQDN zone you want to attach to the service. In our scenario we select the **avsemea.com** zone;
1. Click "OK" to save the configuration change.

When the change to the NSX-T DNS service is effectuated the **avsemea.com** DNS zone will now be listed in the DNS service configuration:

![Advanced DNS Configuration 2](/blog/assets/cloud/2023/avs-ldaps-configure-part2/configure-the-required-DNS-zones-details-2.jpg)

After this step the configuration of the Azure VMware Solution DNS service is complete.
The next article in this series will describe the detailed steps in configuring LDAPS integration through the Azure portal or automation where possible.

[snippets.ps1 file (all code commands)](https://github.com/fskelly/flkelly-cloudblog/blob/main/content/post/2023/avs-ldaps-configure-part1/snippets.ps1)  
[< Previous](../avs-ldaps-configure-part1/) [Next>](../avs-ldaps-configure-part3/)


