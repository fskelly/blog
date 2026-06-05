---
title: "Cli List Locations and Peers"
slug: cli-list-locations-and-peers
description: >-
  How to use the Azure CLI to list Azure Locations and their peers So this will be a "quick post" that shows some great functionality within t...
added: 2021-05-05T07:03:02+02:00
tags:
  - quick-post
  - az-cli
categories:
  - command-line
  - azure
draft: true
---
# How to use the Azure CLI to list Azure Locations and their peers

So this will be a "quick post" that shows some great functionality within the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) with ```az account list-locations```. With this command you can expect some output like below, you actually get a lot of content back.

```bash
{
    "displayName": "Brazil Southeast",
    "id": "/subscriptions/949ef534-07f5-4138-8b79-aae16a71310c/locations/brazilsoutheast",
    "metadata": {
      "geographyGroup": "South America",
      "latitude": "-22.90278",
      "longitude": "-43.2075",
      "pairedRegion": [
        {
          "id": "/subscriptions/949ef534-07f5-4138-8b79-aae16a71310c/locations/brazilsouth",
          "name": "brazilsouth",
          "subscriptionId": null
        }
      ],
      "physicalLocation": "Rio",
      "regionCategory": "Other",
      "regionType": "Physical"
    },
    "name": "brazilsoutheast",
    "regionalDisplayName": "(South America) Brazil Southeast",
    "subscriptionId": null
}

```

If you look at some of the examples, you will also see some *"logical"* locations, example below, there is a way of adding a query to remove these to display only **"physical"** locations.  

```bash
{
  "displayName": "United States",
  "id": "/subscriptions/949ef534-07f5-4138-8b79-aae16a71310c/cations/unitedstates",
  "metadata": {
    "geographyGroup": null,
    "latitude": null,
    "longitude": null,
    "pairedRegion": null,
    "physicalLocation": null,
    "regionCategory": "Other",
    "regionType": "Logical"
  },
  "name": "unitedstates",
  "regionalDisplayName": "United States",
  "subscriptionId": null
}
```

I use a simple query to remove all locations without latitide and in my case simply return the **Region Name** 😄

```bash
az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name}" --output json
```

```bash
{
  "RegionName": "brazilsoutheast"
}
```

So, now to get the paired region, again if we look at the JSON output, there is ALWAYS only 1 result within the array for Paired Region; as per this only 1 paired region 😄. We will use this to our advantage

```bash
az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json
```

```bash
{
  "PairedRegion": "brazilsouth",
  "RegionName": "brazilsoutheast"
}
```

