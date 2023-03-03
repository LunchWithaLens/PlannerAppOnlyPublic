# Scripts to try out the AppOnly APIs

# ToDO - Handle throttling

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

$groups = @()
$groups+=$groupRequest.value
while($null -ne $groupsRequest.'@odata.nextLink'){
    $groupsRequest = Invoke-RestMethod -Uri $groupsRequest.'@odata.nextLink' -Method GET -Headers $headers
    $groups+=$groupsRequest.value
    }
Write-Host "There are $($groups.Count) groups in the tenant" -ForegroundColor Green


#################################################
# List Plans by Group
#################################################

foreach ($group in $groups){

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/groups/" + $group.id + "/planner/plans"
try{
# List plans

    $planListRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

    $groupPlans = @()
    $groupPlans+=$planListRequest.value
    
    while($null -ne $planListRequest.'@odata.nextLink'){
        $planListRequest = Invoke-RestMethod -Uri $planListRequest.'@odata.nextLink' -Method GET -Headers $headers
        $groupPlans+=$planListRequest.value
        }
    
    
    if ($groupPlans.Count){
        Write-Host
        Write-Host "  Group name - $($group.displayName)" -ForegroundColor Green
            foreach ($groupPlan in $groupPlans){
            Write-Host
            Write-Host "   Plans name - $($groupPlan.title)" -ForegroundColor Blue
            $planId = $groupPlan.id
    
        
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

$planTasks = @()
$planTasks+=$taskListRequest.value

while($null -ne $taskListRequest.'@odata.nextLink'){
    $taskListRequest = Invoke-RestMethod -Uri $taskListRequest.'@odata.nextLink' -Method GET -Headers $headers
    $planTasks+=$taskListRequest.value
    } 

if($planTasks.Count){
    Write-Host "    The plan $($groupPlan.title) has $($planTasks.Count) tasks" -ForegroundColor Blue
    foreach ($planTask in $planTasks){
        Write-Host "      Tasks name - $($planTask.title)" -ForegroundColor Cyan


#end task loop
}Write-Host
#end if no tasks in plan
}
else {Write-Host "    The plan $($groupPlan.title) has $($planTasks.Count) tasks" -ForegroundColor Blue}

#end for plan loop
}

#end if no plans in group
}
else {Write-Host "No plans found in Group - $($group.displayName)" -ForegroundColor Magenta}
        
        }catch
                {
                $StatusCode = [int]$_Exception.Response.$StatusCode
                if ($StatusCode -eq 404) {
                    Write-Error "Not found!"
                } elseif ($StatusCode -eq 500) {
                    Write-Error "InternalServerError: Something went wrong on the backend!"
                } else {
                    Write-Error "Expected 200, got $([int]$StatusCode)"
                }
                }

#end group loop
}
