---
title: "Expiring Keys and Secrets within Azure Key Vault"
slug: expiring-keys-azure-key-vault
description: >-
  Find Azure Keyvault expiring keys with PowerShell
added: 2021-01-18T07:06:03+02:00
tags:
  - azure
---
I was working with a customer the other day and a fairly simple ask came up, I however could not find an immediate answer within the portal.  

**How do I check for expiring keys within the Azure KeyVault?**

Now being a PowerShell person, I never gave this much thought as for most tasks or actions I perform on the Azure Platform is done through PowerShell, AP, or CLI. So easy enough, however, not everyone knows how to do this in PowerShell. So, I created a simple script.

My requirements  

1. You can specify the days to check as your expiry window.
2. You can also check for non-expiring keys.  
3. Can be run within the [Cloud Shell](https://shell.azure.com)

For me, it is equally important to check for expiring keys, for key rotation there is a [process](https://docs.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation-dual) to do this. Just as important, if not **__MORE IMPORTANT__** is non-expiring keys (think "password never expires on a Domain Admin account").

I was simply after a quick and easy click and run script. THe script is hosted on my [repo](https://github.com/fskelly/flkelly-AzureCode-powershell) and the specific script can be found [here](https://github.com/fskelly/flkelly-AzureCode-powershell/blob/main/keyVault/az/az_checkForExpiringAndNonExpiringSecrets.ps1)

```powershell
$vaultName = ""
$kvRG = ""
$kv = Get-AzKeyVault -ResourceGroupName $kvRG -VaultName $vaultName
$secrets = Get-AzKeyVaultSecret -VaultName $kv.VaultName

$nonExpiringSecrets = $secrets | Where-Object {$_.Expires -eq $null}
$expiringSecrets = $secrets | Where-Object {$_.Expires -ne $null}

$daysToCheck = 90
$expireDate = (Get-Date).AddDays($daysToCheck)

foreach ($expiringSecret in $expiringSecrets)
{
    if ($expiringSecret.Expires -lt $expireDate)
    {
        Write-Host ($expiringSecret).name "is in the expiry window of $daysToCheck days"
    }
}
foreach ($nonExpiringSecret in $nonExpiringSecrets)
{
    Write-host ($nonExpiringSecret).name " is set to NEVER expire"
}
```

As you can see simply replace the variables that you need to, namely *```$vaultName```* (**name of the Azure Keyvault**) and *```$kvRG```* (**name of the Resource Group housing the Azure Keyvault**)


