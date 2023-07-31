# Scripts to try out the AppOnly APIs
# By User also requires the App Registration to have User.Read.All Application permission
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
# Get Users
#################################################

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/users"

# Read users

$usersRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

$users = @()
$users+=$usersRequest.value
while($null -ne $usersRequest.'@odata.nextLink'){
    $usersRequest = Invoke-RestMethod -Uri $usersRequest.'@odata.nextLink' -Method GET -Headers $headers
    $users+=$usersRequest.value
    }
Write-Host "There are $($users.Count) users in the tenant" -ForegroundColor Green


#################################################
# List Plans and Tasks by User
#################################################

foreach ($user in $users){

$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")

$uri = "https://graph.microsoft.com/v1.0/users/" + $user.id + "/planner/tasks"
try{
# List plans

    $userTasksRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

    $userTasks = @()
    $userTasks+=$userTasksRequest.value
    
    while($null -ne $userTasksRequest.'@odata.nextLink'){
        $userTasksRequest = Invoke-RestMethod -Uri $userTasksRequest.'@odata.nextLink' -Method GET -Headers $headers
        $userTasks+=$userTasksRequest.value
        }
    
    
    if ($userTasks.Count){
        Write-Host
        Write-Host "  User name - $($user.displayName)" -ForegroundColor Green
            foreach ($userTask in $userTasks){
            Write-Host
            Write-Host "   Plan Id - $($userTask.planId)" -ForegroundColor Blue
            Write-Host "   Task name - $($userTask.title)" -ForegroundColor Cyan
            
    
        

#end task loop
}Write-Host
#end if no tasks for user
}

else {Write-Host "No tasks found for user - $($user.displayName)" -ForegroundColor Magenta}
        
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
