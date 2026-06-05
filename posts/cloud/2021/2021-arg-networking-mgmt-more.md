---
title: "Azure Resource Graph - More queries for Networking and Management Groups"
slug: 2021-arg-networking-mgmt-more
description: >-
  More queries for Kusto and Enterprise Scale Landing Zone checks.
added: 2021-12-09T08:00:00+00:00
tags:
  - azure
  - resource-graph
  - blog
  - eslz
categories:
  - azure
  - resource-graph
  - networking
  - management-group
draft: true
---
Just some more queries I have developed.

## Networking

**Don't create unnecessarily large virtual networks (for example, /16) to ensure that IP address space isn't wasted.**

```Kusto
resources
| where type == "microsoft.network/virtualnetworks"
| extend addressSpace = todynamic(properties.addressSpace)
| extend addressPrefix = todynamic(properties.addressSpace.addressPrefixes)
| mvexpand addressSpace
| mvexpand addressPrefix
| extend addressMask = split(addressPrefix,'/')[1]
| where addressMask <= 16
```

Smallest recommended size for a GatewaySubnet is /27

**When you are planning your gateway subnet size, refer to the documentation for the configuration that you are planning to create. For example, the ExpressRoute/VPN Gateway coexist configuration requires a larger gateway subnet than most other configurations. Additionally, you may want to make sure your gateway subnet contains enough IP addresses to accommodate possible future additional configurations. While you can create a gateway subnet as small as /29, we recommend that you create a gateway subnet of /27 or larger (/27, /26 etc.) if you have the available address space to do so. This will accommodate most configurations.** [Microsoft Docs](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsub)

```kusto
resources
| where type == "microsoft.network/virtualnetworks"
| extend subnets = todynamic(properties.subnets)
| mvexpand subnets
| project VNetname=name,SubnetName=subnets.name, resourceGroup, location, CIDR=subnets.properties.addressPrefix, id
| where SubnetName == 'GatewaySubnet'
| extend subnetMask = split(CIDR,'/')[1]
| where subnetMask >= 27
```

**Use IP addresses from the address allocation for private internets (RFC 1918).**[Plan for IP addressing](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/plan-for-ip-addressing)

```kusto
resources | where type == 'microsoft.network/virtualnetworks' | extend addressSpace = todynamic(properties.addressSpace) | extend addressPrefix = todynamic(properties.addressSpace.addressPrefixes) | mvexpand addressSpace | mvexpand addressPrefix | project name, id, location, resourceGroup, subscriptionId, cidr = addressPrefix | where cidr matches regex @'^(?:10|127|172\\.(?:1[6-9]|2[0-9]|3[01])|192\\.168)\\..*'
```

```kusto
resources | where type == 'microsoft.network/virtualnetworks' | extend addressSpace = todynamic(properties.addressSpace) | extend addressPrefix = todynamic(properties.addressSpace.addressPrefixes) | mvexpand addressSpace | mvexpand addressPrefix | project name, id, location, resourceGroup, subscriptionId, cidr = addressPrefix | where not (cidr matches regex @'^(?:10|127|172\\.(?:1[6-9]|2[0-9]|3[01])|192\\.168)\\..*')
```

**Don't create unnecessarily large virtual networks (for example, /16) to ensure that IP address space isn't wasted. [Plan for IP addressing](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/plan-for-ip-addressing)**

```kusto
resources | where type == 'microsoft.network/virtualnetworks' | extend addressSpace = todynamic(properties.addressSpace) | extend addressPrefix = todynamic(properties.addressSpace.addressPrefixes) | mvexpand addressSpace | mvexpand addressPrefix | extend addressMask = split(addressPrefix,'/')[1] | where addressMask > 16 | project name, id, subscriptionId, resourceGroup, addressPrefix
```

```kusto
resources | where type == 'microsoft.network/virtualnetworks' | extend addressSpace = todynamic(properties.addressSpace) | extend addressPrefix = todynamic(properties.addressSpace.addressPrefixes) | mvexpand addressSpace | mvexpand addressPrefix | extend addressMask = split(addressPrefix,'/')[1] | where addressMask <= 16 | project name, id, subscriptionId, resourceGroup, addressPrefix
```

## Management Groups

**Keep the management group hierarchy reasonably flat, with no more than three to four levels ideally. This restriction reduces management overhead and complexity.**
  [Define a management group hierarchy](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/management-group-and-subscription-organization)  

```kusto
resourcecontainers
| where type == "microsoft.resources/subscriptions"
| extend ManagementGroup = tostring(tags),mgmtChain = properties.managementGroupAncestorsChain
| where array_length(mgmtChain) ==1
|mvexpand mgmt=mgmtChain
|project id, subName = name, subscriptionId, managedBy, managementGroupName = mgmt.displayName
```
  
```kusto
resourcecontainers
| where type == "microsoft.resources/subscriptions"
| extend ManagementGroup = tostring(tags),mgmtChain = properties.managementGroupAncestorsChain
| where array_length(mgmtChain) >=4
|mvexpand mgmt=mgmtChain
```

Follow me for more.  
[Twitter](https://twitter.com/fskelly)  
[LinkedIn](https://www.linkedin.com/in/fletcherkelly/)

