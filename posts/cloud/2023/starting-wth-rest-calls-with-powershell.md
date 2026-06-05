---
title: "Starting Wth API Rest Calls With Powershell"
slug: starting-wth-rest-calls-with-powershell
description: >-
  What are we doing? I am working more and more with the Azure REST APIs now. My first dive into cost management was a big hit, so I am expand...
added: 2023-08-17T09:09:54+01:00
tags:
  - powershell
  - rest
  - api
categories:
  - azure
  - azure-native
draft: true
---
## What are we doing?

I am working more and more with the Azure REST APIs now. My [first dive into cost management](https://cloud.fskelly.com/post/2023/azure-cost-management-playing-with-api-in-powershell/) was a big hit, so I am expanding on that. The main consideration around that particular API is that is it open. By this, I mean a simple HTTP request will return results, no authentication or additional headers or the like are needed. So nice and easy. As we dive more into API and REST API's, this is likely to change. This post, with more planned, is designed to make this easier and break it down into smaller chunks. THese chunks/snippets can be re-used and the principles in the chunks/snippets can be applied to other API's. These in particular are aimed at Azure API's.

## Constraints / limitations

1. Primary focus is on the Azure API.
1. Using Azure Tokens.
1. Enterprise Application is already registered.
1. You have securely stored your secret for the above point.
1. Designed to be modular - so you can run these in snippets/sections.
1. This is **NOT PRODUCTION** ready yet.

## Lets build this

Reminder, you will need to have an Application ID, Secret value and Tenant ID on hand as these are needed as part of the API call. [Here](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app) is a guide for registering an Azure AD application for testing purposes. Please note that additional controls are needed for production environments.

For production scenarios, secret management should be used as the variables should **NOT** be saved in the file, but instead in a [Azure Keyvault](https://azure.microsoft.com/en-us/products/key-vault) and then read out as needed in the script/function/....

The process flow for this is as follows.  
Perform a rest API Call to get a token -> Save Token in variable -> Use saved variable for subsequent calls.  

### Get Azure AD Token  

In this script I am using prompts and obfuscating in the script with the use of the _"-AsSecureString"_. This will then save the acquired token in the **$token** variable.

```powershell
$tenantId = Read-Host "Enter your Azure tenant ID"
$clientID = Read-Host "Enter your Azure client ID"
$clientSecret = Read-host "enter your client secret" -AsSecureString

$normalString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))

$params = @{
    Uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    Method = "POST"
    Body = @{
        grant_type = "client_credentials"
        scope = "https://management.azure.com/.default"
        client_id = $clientID
        client_secret = $normalString
    }
}

$authResult = Invoke-RestMethod @params

# Output the access token
$token = $authResult.access_token
```

Now we have our token and we can move onto the next phase, for this I am using a simple Rest API call to get my resource groups, but this token can be used for any api in the [_**"https://management.azure.com/"**_](https://management.azure.com/) scope, so this would NOT work for an Azure OpenAI Rest API call as the scope is different. A quick search with your choice of search engine will get the correct scope for that. I will create another blog about that soon.

### Getting resource groups with an API call

You will see here that the API call needs authorization (US Spelling) and we are using the token from earlier _"Authorization" = "Bearer $token"_.

```powershell
$subscriptionId = read-host "Enter your subscription ID"
$apiVersion = "2020-09-01"

$headers = @{
    "Authorization" = "Bearer $token"
}

$params = @{
    Uri = "https://management.azure.com/subscriptions/$subscriptionId/resourcegroups?api-version=$apiVersion"
    Method = "GET"
}

$queryResult = Invoke-RestMethod @params -Headers $headers 
$queryResult.value | select-object -Property name,location
```

This same principle can be applied to any API call, just change the scope and the API call. I will be adding more to this as I go along, but this is a good start.

