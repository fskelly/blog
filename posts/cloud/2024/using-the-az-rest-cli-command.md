---
title: "Using the AZ Rest CLI command"
slug: using-the-az-rest-cli-command
description: >-
  What are we doing? With this post I am going to show you how you can easily do Azure API calls and “skip” a lot of the difficult items. I ha...
added: 2024-08-29T16:00:56Z
tags:
  - azure
draft: true
---
What are we doing?

With this post I am going to show you how you can easily do Azure API calls and “skip” a lot of the difficult items. I have been on something interesting tools to help my customers, when I can talk more about it, I will. As part of this tooling exercise, the Azure REST API is used extensively. With “normal” applications like APIDog, ThunderClient and the like, you often need to get a token and then add this to the header as an auth object and this involves configuration on EntraID and the like. This is not necessarily the best approach for what I was looking for. I was looking for a quick testing framework for Azure REST API calls and then look at the output to be further extracted / manipulated with JQ.

These are the principal / considerations

1. This is NOT designed to replace a full API solution like APIDog or Postman or ThunderClient
1. Designed for quick queries against the Azure REST API
1. Uses the currently logged on person credentials to run queries

Ok, so down to business, the tool/command that I am using is “az rest”. Using this tool is quite easy but thanks to some additional insights from a colleague in my team you can make it even easier. So, how do we use the command. Let’s say we wanted to make the following request – Virtual Machines – List.

The command looks like this.

```bash
GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines?api-version=2024-07-01
```

We need to provide some variable(s) or information as marked by items in braces (“{}”), so we need to provide **"subscriptionId"** and **"resourceGroupName"**. I will endeavour to provide as much information as possible, however for safety reason, some items will be obfuscated.

**Please remember to login first az login, as the az rest command uses the context of the currently authenticated to Azure user, hence no auth tokens.**

Here is a quick shell script to show this and allow you to test.

```bash
# Set your variables here
subscriptionId="<your_subscription_id>"
resourceGroupName="<your_resource_group_name>"
 
# Construct the URL
url="https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Compute/virtualMachines?api-version=2024-07-01"
 
# Use az rest command
az rest --method get --url $url

```

You will get a result similar to the below,

![az rest result](/blog/assets/cloud/2024/using-the-az-rest-cli-command/result1.png)
For me and the testing I am doing, this is a great, rapid and repeatable way of testing queries and quickly testing if the URI is valid before spending many hours troubleshooting the **"why is this not working"** versus **"is my URI correct"**.

What is also quite handy is the fact that the **"<https://management.azure.com>"** aspect can be dropped as this is already assumed, and as such you run a query directly against the ID to get more information or an ID returned from an Azure Resource Graph Query, with the correct API version appended in this example

![az rest result2](/blog/assets/cloud/2024/using-the-az-rest-cli-command/result2.png)

Without the API Version appended

![failure](/blog/assets/cloud/2024/using-the-az-rest-cli-command/failure.png)

With the correct API version appended 👍

![failure](/blog/assets/cloud/2024/using-the-az-rest-cli-command/image-4.png)

![failure](/blog/assets/cloud/2024/using-the-az-rest-cli-command/image-5.png)

You can now do the same process with other IDs that are returned.

