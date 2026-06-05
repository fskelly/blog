---
title: "Azure VMware Solution: A comprehensive guide to LDAPS identity integration - Part 4"
slug: avs-ldaps-configure-part4
description: >-
  Author(s): Robin Heringa and Fletcher Kelly Implementing LDAPS identity integration with Azure VMware Solution series 4 of 4 This is the fou...
added: 2023-01-25T08:45:43Z
tags:
  - avs
  - identity
  - ldaps
draft: true
---
Author(s): [Robin Heringa](/about/robinheringa/) and [Fletcher Kelly](/about/fletcherkelly/) 

# Implementing LDAPS identity integration with Azure VMware Solution series - 4 of 4 #

This is the fourth and final part of the blog series on how to implement LDAPS identity integration with Azure VMware Solution. Other parts of this series can be found here: 

1. [LDAPS integration - part 1 of 4](../avs-ldaps-configure-part1/)
1. [LDAPS integration - part 2 of 4](../avs-ldaps-configure-part2/)
1. [LDAPS integration - part 3 of 4](../avs-ldaps-configure-part3/)

These steps, for now, are run manually from the Azure Portal. This will be found "Azure VMware Solution" and under Operations, Run command. Then select "New-LDAPSIdentitySource". An automated way of executing the run-command is in the making. Please check back soon as this article will be updated as soon as this is available.
Navigate to Azure Portal and ensure you are on AVS Private Cloud blade

1. In the AVS Private Cloud blade, click "Run Command";
1. Ensure Packages is selected.
1. Click "New-LDAPSIdentitySource".
1. Ensure the correct Run is open before populating the required information.

![run-command-pane](/blog/assets/cloud/2023/avs-ldaps-configure-part4/1-run-command-1.jpg)

Populate the information as needed.

The SSLCertificateSasUrl is a single string consisting of the SASTokens separated with a "**,**". For example:
{{< highlight go >}}
https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc001.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed],https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc002.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed] 
{{< /highlight >}} and **pasted as a single long string**.

**Example string:**
{{< highlight shell >}}
https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc001.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed],https://avsgwcsa14a2c2da.blob.core.windows.net/ldaps-blog-post/avs-gwc-dc002.cer?sv=2021-10-04&st=2023-01-12T13%3A46%3A45Z&se=2023-01-13T13%3A46%3A45Z&sr=b&sp=rwd&[Removed]{{< /highlight >}}

The other values would need to be updated as per your environment. The BaseDNGroups and BaseDNUsers are the **D**istinguished **N**ames  for the groups and users. These can be found using the ADSIedit tool and navigating to the required groups within Active Directory and noting down these values. More information can be here about [Distinguished Names](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ldap/distinguished-names)

With the BaseDNGroups and BaseDNUsers, watch the values used as these should be under the same tree. In this example, **"OU=Corp,DC=avsemea,DC=com"**

![run-command-pane](/images/blogImages/2023/avs-ldaps-configure-part4/2-run-command-populated.jpg)

![run-command-execute](/images/blogImages/2023/avs-ldaps-configure-part4/3-run-command-run.jpg)

Once all information is entered, Run the command. You can check the status of the Run command within the portal.
Navigate to Azure Portal and ensure you are on AVS Private Cloud blade

1. In the AVS Private Cloud blade, click "Run Command";
1. Ensure "Run execution status" is selected.
1. Click the latest run execution that is applicable to your environment. In this case, **New-LDAPSIdentitySource-Exec33**.
1. Ensure you click the Execution name (3.) that is the running state.

![run-command-execute-status](/images/blogImages/2023/avs-ldaps-configure-part4/4-run-command-execution-status.jpg)

You can check the status of the job now and you are waiting for all the tasks to be completed and show that your selected group was added to CloudAdmins
Once you have clicked the Execution name link

1. Check the information tab to see the steps being executed by the script;

![run-command-execute](/images/blogImages/2023/avs-ldaps-configure-part4/5-run-command-execution-status-2.jpg)

You can also check the output and ensure that the correct name was added.
Once you have clicked the Execution name link

1. Check the Output tab to see the steps being executed by the script;

![run-command-execute-1](/images/blogImages/2023/avs-ldaps-configure-part4/6-run-command-execution-status-3.jpg)

You can log on with LDAP based credentials. Using the link found under "VMware credentials", navigate to vCenter Server Credentials Web client URL
Navigate to Azure Portal and ensure you are on AVS Private Cloud blade

1. In the AVS Private Cloud blade, click "VMware credentials";
1. Click the copy icon for the WebClient URL under "vCenter Server credentials"

![vmware-urls](/images/blogImages/2023/avs-ldaps-configure-part4/7-vmware-creds.jpg)

Navigate to the URL with your browser of choice and use your Directory Services based credentials to ensure that login and authentication is working as expected.

![ldaps vmware url logon 1](/images/blogImages/2023/avs-ldaps-configure-part4/8-vmware-external-creds-checking-1.jpg)

![ldaps vmware url logon 2](/blog/assets/cloud/2023/avs-ldaps-configure-part4/9-vmware-external-creds-checking-2.jpg)

Logon to Azure VMware Solution based components is now possible and should be now be working as expected.

[snippets.ps1 file (all code commands)](https://github.com/fskelly/flkelly-cloudblog/blob/main/content/post/2023/avs-ldaps-configure-part1/snippets.ps1)  
[< Previous](../avs-ldaps-configure-part3/)

