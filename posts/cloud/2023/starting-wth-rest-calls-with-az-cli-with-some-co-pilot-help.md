---
title: "Starting Wth Rest Calls With AzCli With Some Copilot Help"
slug: starting-wth-rest-calls-with-az-cli-with-some-co-pilot-help
description: >-
  What are we doing? I am working more and more with the Azure REST APIs now. My previous post using API with Powershell got me thinking about...
added: 2023-10-11T13:34:50+01:00
tags:
  - azure-cli
  - rest
  - api
  - copilot
categories:
  - azure
  - azure-native
  - ai
draft: true
---
## What are we doing?

I am working more and more with the Azure REST APIs now. My [previous post using API with Powershell](https://cloud.fskelly.com/post/2023/starting-wth-rest-calls-with-powershell/) got me thinking about opening the idea to go beyond [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/overview). I am very open with people around my lack of skill with [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/), I do however want to learn some new things.

We also have this great technology called [GitHub Copilot](https://github.com/features/copilot) and [ChatGPT](https://openai.com/blog/chatgpt), so I figured let me dig into "AI" as I am a techy at heart and let me improve my skills with Azure CLI.

As a result, the script below actually has two "flavours" or options available in certain places. This is simply because the two different AI's have different suggestions. I have left both in as I think it is interesting to see the differences and they actually work in slightly different ways. The one approach is to use the context of the currently logged on person and the other uses the "traditional" approach of using an app registration.

## Constraints / limitations

1. Primary focus is on the Azure API.
1. Using Azure Tokens.
1. Enterprise Application is already registered. (Not strictly needed for the CLI version that uses the currently logged on person's context.)
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

```bash
#option 1

read -p "Enter your Azure tenant ID: " tenantId
read -p "Enter your Azure client ID: " clientId
read -s -p "Enter your client secret: " clientSecret
echo ""

accessToken=$(curl -X POST -d "grant_type=client_credentials&scope=https://management.azure.com/.default&client_id=$clientId&client_secret=$clientSecret" "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" | jq -r '.access_token')

echo "Token is $accessToken"
```

```bash
#option 2

az login --scope https://management.core.windows.net//.default

read -p "Enter your Azure tenant ID: " tenantId
#read -p "Enter your Azure client ID: " clientId
#read -sp "Enter your client secret: " clientSecret

authResult=$(az account get-access-token --tenant=$tenantId --query "accessToken" --output tsv)

if [ -z "$authResult" ]; then
    echo "Token is empty"
else
    # Output the access token
    token=${authResult#*\"access_token\":\"}; token=${token%%\"*}
    echo "Token is $token"
fi
```

Now we have our token and we can move onto the next phase, for this I am using a simple Rest API call to get my resource groups, but this token can be used for any api in the [_**"https://management.azure.com/"**_](https://management.azure.com/) scope, so this would NOT work for an Azure OpenAI Rest API call as the scope is different. A quick search with your choice of search engine will get the correct scope for that. I will create another blog about that soon.

### Getting resource groups with an API call

You will see here that the API call needs authorization (US Spelling) and we are using the token from earlier _"Authorization" = "Bearer $token"_.

```bash
read -p "Enter your subscription ID: " subscriptionId
apiVersion="2020-09-01"

# step below can be used to get the access token for the current session
#accessToken=$(az account get-access-token --resource=https://management.azure.com --query accessToken -o tsv)

headers="Authorization: Bearer $accessToken"
uri="https://management.azure.com/subscriptions/$subscriptionId/resourcegroups?api-version=$apiVersion"
queryResult=$(curl -s -H "$headers" -X GET $uri)
echo $queryResult | jq -r '.value[] | {name: .name, location: .location}'
```

This same principle can be applied to any API call, just change the scope and the API call. I will be adding more to this as I go along, but this is a good start.

