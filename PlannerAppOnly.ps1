# Scripts to try out the AppOnly APIs

# MSAL.PS added to the function to support the MSAL libraries
# Available from https://github.com/AzureAD/MSAL.PS or https://www.powershellgallery.com/packages/MSAL.PS
# Or Install-Module MSAL.PS -AcceptLicense
Import-Module MSAL.PS

# Az PowerShell module used to read the App Registration properties from KeyVault
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
# Install-Module -Name Az.KeyVault -force
Connect-AzAccount -Tenant "<Azure Sub Tenant GUID>" -Subscription "<Subscription Name>" -AuthScope KeyVault
$clientIdss = (Get-AzKeyVaultSecret -VaultName "<VaultName>" -SecretName "plannerAppId").SecretValue
$clientId = ConvertFrom-SecureString -AsPlainText $clientIdss
$clientSecret = (Get-AzKeyVaultSecret -VaultName "<VaultName>" -SecretName "plannerAppSecret").SecretValue

# Client ID is created in Azure AD under App Registration - requires Group.Read.All and the default User.Read
# Redirect Url is Mobile and Desktop applications - https://login.microsoftonline.com/common/oauth2/nativeclient
# Change TenantId to your own tenant 

$graphToken = Get-MsalToken -ClientId $clientId -clientSecret $clientSecret -TenantId "<M365 Tenant Guid>" 

#################################################
# Get Groups
#################################################

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/groups"

# Read groups

$groupRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

$groups = $groupRequest.value
$groups.Count
# I was wanting to look at a specific group that I didn't belong to
$groups[33].displayName
$groupId = $groups[33].id

#################################################
# List Plans by Group
#################################################

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/groups/" + $groupId + "/planner/plans"

# List plans

$planListRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$groupPlans = $planListRequest.value
$groupPlans[0].title
$planId = $groupPlans[0].id
$planId


#################################################
# List Tasks by Plan
# 
#################################################

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/planner/plans/" + $planId + "/tasks"

# List tasks

$taskListRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$planTasks = $taskListRequest.value
$planTaskTitle = $planTasks[0].title
$planTaskTitle


