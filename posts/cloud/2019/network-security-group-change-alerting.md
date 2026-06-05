---
title: "Network Security Group Change Alerting"
slug: network-security-group-change-alerting
description: >-
  So, I was with a customer and they are asking for a fairly standard alert. "Please alert me when an NSG is added or modified" . Seems simply...
added: 2019-02-20T08:21:49+02:00
tags:
  - nsg
  - azure-monitor
---
So, I was with a customer and they are asking for a fairly standard alert.  

**"Please alert me when an NSG is added or modified"**. Seems simply enough, however this is not as simply as you think. So I used my favourite search and found the following, “How to receive an email on Azure Network Security Group Rule changes“, this is great content and after testing, it works exactly as expected. I just found one little concern with this approach; this is simply finding the required ID for the action group. I have now investigated and found some code to make this a little easier.

AZ CLI

```bash
az monitor action-group list
```

PowerShell

```powershell
Get-AzActionGroup
```

Hope this helps people in the field to find the Resource Group ID more easily.


