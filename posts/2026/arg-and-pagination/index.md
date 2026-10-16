---
added:  '2026-08-18T12:02:29+01:00'
title: 'Azure Resource Graph, Scripting and Pagination'
tags:
    - 'azure'
    - 'resource graph'
    - 'powershell'
categories:
    - "Azure"
topics:
    - "Resource Graph"
    - "Scripting"
    - "PowerShell"
slug: 2026-azure-resource-graph-scripting-and-pagination
description: 'Dealing with pagination when using Azure Resource Graph and scripting with PowerShell.'
---

When using Azure Resource Graph and scripting, how can I deal with pagination?

<!--more-->

I was working on a customer issue the other day. They needed to get a lot of results from the Azure Resource Graph. I was using the `Search-AzGraph` cmdlet to get the results. The problem was that the results were paginated and I needed to get all the results. I was able to get all the results by using the `-First` parameter and setting it to a high number. This worked, but it was not ideal. I wanted to find a better way to deal with pagination.

Pagination is part of the problem and how we deal with that, however this particular also had a significant number of subscriptions to deal with as well. This added a layer of complexity to the problem. So how did I approach this problem? I used a combination of 2 items.

1. [Process each subscription at a time](#1-process-each-subscription-at-a-time)
2. [Handle pagination for each subscription](#2-handle-pagination-for-each-subscription)

## 1. Process each subscription at a time

We will get a list of all the subscriptions, save these into a variable and then process each subscription one at a time. This will allow us to deal with the pagination for each subscription.

```powershell
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Set-AzContext -Subscription $subscription
    # Handle pagination for this subscription
}
```

## 2. Handle pagination for each subscription

In essence - this is the full code block that I used to get all the results from the Azure Resource Graph for each subscription and handle pagination. The only thing you need to add or modify is the `$query` variable. This is the query that you want to run against the Azure Resource Graph. You can use the [Azure Resource Graph Explorer](https://resources.azure.com/) to build your query and then copy it into the `$query` variable.

```powershell

foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    # 2. Initialize variables 

    $AllResults = [System.Collections.Generic.List[System.Object]]::new() 
    $SkipToken = $null 
    $PageSize = 1000 # Max allowed per page by Azure Graph API 
    $PageCount = 1
    Write-Host "Starting Azure Resource Graph search..." -ForegroundColor Cyan
    write-output "Querying subscription $subscriptionId with page size $PageSize"
    # 3. Pagination loop
    do {
        Write-Host "Fetching page $PageCount..." -ForegroundColor Yellow
        # Splatting parameters for cleaner code
        $Params = @{
            Query        = $query
            Subscription = $subscriptionId
            First        = $PageSize
        }
        if ($SkipToken) {
            $Params.SkipToken = $SkipToken
        }
        # Execute query and do not turn request failures into an empty result set.
        try {
            $Response = Search-AzGraph @Params -ErrorAction Stop
        }
        catch {
            throw "Azure Resource Graph query failed for subscription $subscriptionId`: $($_.Exception.Message)"
        }

        if ($null -eq $Response) {
            throw "Azure Resource Graph returned no response for subscription $subscriptionId."
        }
        #write-output "Found $($Response.Data.Count) results for subscription $subscriptionId"

        # Collect data safely whether it's an array or single object
        if ($Response.Data) {
            $AllResults.AddRange([array]$Response.Data)
        }
        # Extract the next page token
        $SkipToken = $Response.SkipToken
        $PageCount++
    } while ($SkipToken)
    # 4. Output summary and data
    Write-Host "Completed! Retrieved $($AllResults.Count) total records across $($PageCount - 1) pages." -ForegroundColor Green
    # Return the full dataset to the pipeline or host
    #$AllResults | Format-Table
    $AllResults | export-csv ($subscriptionId + ".csv")
}
```

## Full example with a safe query

```powershell
$query = @'
securityresources
    | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols/regulatorycomplianceassessments" | extend scope = properties.scope
     | where isempty(scope) or  scope in~("Subscription", "MultiCloudAggregation")
    | parse id with * "regulatoryComplianceStandards/" complianceStandardId "/regulatoryComplianceControls/" complianceControlId "/regulatoryComplianceAssessments" *
    | extend complianceStandardId = replace( "-", " ", complianceStandardId)
    | where complianceStandardId ==  "Microsoft cloud security benchmark" 
    | extend failedResources = toint(properties.failedResources), passedResources = toint(properties.passedResources),skippedResources = toint(properties.skippedResources)
    | where failedResources + passedResources + skippedResources > 0 or properties.assessmentType == "MicrosoftManaged"
    | extend joinKey = iff(tostring(properties.assessmentType) =~ "assessmentCategory", tolower(tostring(properties.description)), name)
    | join kind = leftouter(
    securityresources
    | where type == "microsoft.security/assessments"
    | extend scope = properties.scope
     | where isempty(scope) or  scope in~("Subscription", "MultiCloudAggregation")
    | extend recCategory = tostring(properties.metadata.recommendationCategory)
    | extend joinKey = iff(isempty(recCategory) or recCategory in ("Unknown"), name, tolower(recCategory))
    | extend resourceSource = (// AssessmentsQueryBuilder.columnDefinitions.source
                iff(type == "microsoft.security/assessments", trim(' ', tolower(coalesce(tostring(properties.resourceDetails.Source), tostring(properties.resourceDetails.source)))), dynamic(null)))
    | extend resourceId = tostring((// AssessmentsQueryBuilder.columnDefinitions.resourceId
                iff(type == "microsoft.security/assessments", tolower(trim(" ", tostring(case(resourceSource =~ "azure", coalesce(properties.resourceDetails.Id, properties.resourceDetails.id),
            (// AssessmentsQueryBuilder.predicates.newAwsAssessmentIndicator
            (type == "microsoft.security/assessments" and (resourceSource =~ "aws" and isnotempty(tostring(properties.resourceDetails.ConnectorId))))), coalesce(properties.resourceDetails.Id, properties.resourceDetails.id),
            (// AssessmentsQueryBuilder.predicates.newGcpAssessmentIndicator
            (type == "microsoft.security/assessments" and (resourceSource =~ "gcp" and isnotempty(tostring(properties.resourceDetails.ConnectorId))))), coalesce(properties.resourceDetails.Id, properties.resourceDetails.id),
            resourceSource =~ "aws", properties.resourceDetails.AzureResourceId,
            resourceSource =~ "gcp", properties.resourceDetails.AzureResourceId,
            split(id, "/providers/Microsoft.Security/assessments/")[0]
            )))), dynamic(null))))
    | extend resourceName = tostring((// AssessmentsQueryBuilder.columnDefinitions.resourceName
                iff(type == "microsoft.security/assessments", tostring(coalesce(properties.resourceDetails.ResourceName, properties.resourceDetails.resourceName, properties.additionalData.CloudNativeResourceName, properties.additionalData.ResourceName, properties.additionalData.resourceName, split(resourceId, '/')[-1])), dynamic(null))))
    | project subscriptionId, joinKey, id, properties, resourceGroup, resourceId, resourceName, resourceSource
    ) on subscriptionId, joinKey
    | extend complianceState = tostring(properties.state)
    | extend recommendationId = iff(isnull(id1) or isempty(id1), id, id1)
    | extend regexResourceId = extract_all(@"/providers/[^/]+(?:/([^/]+)/[^/]+(?:/[^/]+/[^/]+)?)?/([^/]+)/([^/]+)$", resourceId)[0]
    | extend resourceType = iff(resourceSource in ("aws", "gcp") and isnotempty(tostring(properties1.resourceDetails.ConnectorId)), tostring(coalesce(properties1.additionalData.ResourceType, properties1.additionalData.resourceType)) , iff(regexResourceId[1] != "", regexResourceId[1], iff(regexResourceId[0] != "", regexResourceId[0], "subscriptions")))
    | extend recommendationName = name
    | extend recommendationDisplayName = tostring(iff(isnull(properties1.displayName) or isempty(properties1.displayName), properties.description, properties1.displayName))
    | extend description = tostring(properties1.metadata.description)
    | extend remediationSteps = tostring(properties1.metadata.remediationDescription)
    | extend severity = tostring(properties1.metadata.severity)
    | extend azurePortalRecommendationLink = tostring(properties1.links.azurePortal) | mvexpand statusPerInitiative = properties1.statusPerInitiative
                | extend expectedInitiative = statusPerInitiative.policyInitiativeName =~ "ASC Default"
                | summarize arg_max(expectedInitiative, *) by complianceControlId, recommendationId
                | extend state = iff(expectedInitiative, tolower(statusPerInitiative.assessmentStatus.code), tolower(properties1.status.code))
                | extend notApplicableReason = iff(expectedInitiative, tostring(statusPerInitiative.assessmentStatus.cause), tostring(properties1.status.cause))
                | project-away expectedInitiative 
    | project complianceStandardId, complianceControlId, complianceState, subscriptionId, resourceGroup = resourceGroup1 ,resourceType, resourceName, resourceId, recommendationId, recommendationName, recommendationDisplayName, description, remediationSteps, severity, state, notApplicableReason, azurePortalRecommendationLink| join kind = leftouter (securityresources
    | where type == "microsoft.security/regulatorycompliancestandards/regulatorycompliancecontrols"
    | parse id with * "regulatoryComplianceStandards/" complianceStandardId "/regulatoryComplianceControls/" *
    | extend complianceStandardId = replace( "-", " ", complianceStandardId)
    | where complianceStandardId == "Microsoft cloud security benchmark"
    | where properties.state != "Unsupported"
    | extend controlName = tostring(properties.description)
    | project controlId = name, controlName
    | distinct controlId, controlName) on $right.controlId == $left.complianceControlId
            | project-away controlId
            | distinct *
            | order by complianceControlId asc, recommendationId asc
'@

$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    # 2. Initialize variables 

    $AllResults = [System.Collections.Generic.List[System.Object]]::new() 
    $SkipToken = $null 
    $PageSize = 1000 # Max allowed per page by Azure Graph API 
    $PageCount = 1
    Write-Host "Starting Azure Resource Graph search..." -ForegroundColor Cyan
    write-output "Querying subscription $subscriptionId with page size $PageSize"
    # 3. Pagination loop
    do {
        Write-Host "Fetching page $PageCount..." -ForegroundColor Yellow
        # Splatting parameters for cleaner code
        $Params = @{
            Query        = $query
            Subscription = $subscriptionId
            First        = $PageSize
        }
        if ($SkipToken) {
            $Params.SkipToken = $SkipToken
        }
        # Execute query and do not turn request failures into an empty result set.
        try {
            $Response = Search-AzGraph @Params -ErrorAction Stop
        }
        catch {
            throw "Azure Resource Graph query failed for subscription $subscriptionId`: $($_.Exception.Message)"
        }

        if ($null -eq $Response) {
            throw "Azure Resource Graph returned no response for subscription $subscriptionId."
        }
        #write-output "Found $($Response.Data.Count) results for subscription $subscriptionId"

        # Collect data safely whether it's an array or single object
        if ($Response.Data) {
            $AllResults.AddRange([array]$Response.Data)
        }
        # Extract the next page token
        $SkipToken = $Response.SkipToken
        $PageCount++
    } while ($SkipToken)
    # 4. Output summary and data
    Write-Host "Completed! Retrieved $($AllResults.Count) total records across $($PageCount - 1) pages." -ForegroundColor Green
    # Return the full dataset to the pipeline or host
    #$AllResults | Format-Table
    $AllResults | export-csv ($subscriptionId + ".csv")
}
```