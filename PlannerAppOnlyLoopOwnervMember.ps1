# MSAL.PS added to the function to support the MSAL libraries
# Available from https://github.com/AzureAD/MSAL.PS or https://www.powershellgallery.com/packages/MSAL.PS
# Or Install-Module MSAL.PS -AcceptLicense
 
Import-Module MSAL.PS
 
# Az PowerShell module used to read the App Registration properties from KeyVault
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
# Install-Module -Name Az.KeyVault -force
 
Connect-AzAccount -Tenant "<tenant id for Azure Subscription>" -Subscription "<name of subscription>" -AuthScope KeyVault

$clientIdss = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "plannerAppId").SecretValue
$clientId = ConvertFrom-SecureString -AsPlainText $clientIdss
$clientSecret = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "plannerAppSecret").SecretValue
 
# Interactive login
# Client ID is created in Azure AD under App Registration - requires Group.Read.All and the default User.Read
# Redirect Url is Mobile and Desktop applications - https://login.microsoftonline.com/common/oauth2/nativeclient
# Change TenantId to your own tenant 
 
$graphToken = Get-MsalToken -ClientId $clientId -clientSecret $clientSecret -TenantId "<tenant id of M365 tenant>" 
 
#################################################
# Get Groups
#################################################
 
$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")
$uri = "https://graph.microsoft.com/v1.0/groups"
 
# Read groups
 
$groupRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
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
$totalOwnersNotMembers = @()
foreach ($group in $groups){
$headers = @{}
$headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
$headers.Add('Content-Type', "application/json")
$uri = "https://graph.microsoft.com/v1.0/groups/" + $group.id + "/planner/plans"
try{

# List plans
 
    $planListRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    $groupPlans = @()
    $groupPlans+=$planListRequest.value
    
    while($null -ne $planListRequest.'@odata.nextLink'){
        $planListRequest = Invoke-RestMethod -Uri $planListRequest.'@odata.nextLink' -Method GET -Headers $headers
        $groupPlans+=$planListRequest.value
        }
# In this case I'm not listing plans - just getting Groups that contain plans and checking owners v members    
    
    if ($groupPlans.Count){
        Write-Host
        Write-Host "  Group name - $($group.displayName) has $($groupPlans.Count) plans" -ForegroundColor Green
  
# Get Owners in this Group
 
$uri = "https://graph.microsoft.com/v1.0/groups/" + $group.id + "/owners?$select=id,displayName"
 
# Read Owners
 
$ownerRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$owners = @()
$owners+=$ownerRequest.value
while($null -ne $ownersRequest.'@odata.nextLink'){
    $ownersRequest = Invoke-RestMethod -Uri $ownersRequest.'@odata.nextLink' -Method GET -Headers $headers
    $owners+=$ownerRequest.value
    }

Write-Host "There are $($owners.Count) Owners in the group" -ForegroundColor Green
 
# Get Member in this Group

$uri = "https://graph.microsoft.com/v1.0/groups/" + $group.id + "/members?$select=id,displayName"
 
# Read members
 
$ownerRequest = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$members = @()
$members+=$ownerRequest.value
while($null -ne $membersRequest.'@odata.nextLink'){
    $membersRequest = Invoke-RestMethod -Uri $membersRequest.'@odata.nextLink' -Method GET -Headers $headers
    $members+=$ownerRequest.value
    }

Write-Host "There are $($members.Count) members in the group" -ForegroundColor Green
 
###############################
# Which Owners are not members?
###############################

$ownersNotMembers = Compare-Object -ReferenceObject $owners -DifferenceObject $members -Property id | Where-Object {$_.SideIndicator -eq "<="}
If($ownersNotMembers.Count){
    $totalOwnersNotMembers += $ownersNotMembers | Select-Object *, @{Name="GroupId"; Expression={$group.Id}},@{Name="GroupCreated"; Expression={$group.createdDateTime}}
    Write-Host "The following Ids identify Owners who are no members" -ForegroundColor Red
    $ownersNotMembers
}
#end for plan loop
            }
#end if no plans in group
       
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
Write-Host "The full list of Groups with Owners who are not members:"
$totalOwnersNotMembers 
 
############################################
# Check if the owners should be made members
############################################
If($totalOwnersNotMembers){
    $answer = Read-Host "Do you want to make the owners who are not members, members too? (yes/no)"
    if ($answer -eq "yes") {
    foreach($row in $totalOwnersNotMembers){
        $headers = @{}
        $headers.Add('Authorization','Bearer ' + $graphToken.AccessToken)
        $headers.Add('Content-Type', "application/json")
    
        $body = @{}
        $userRef = "https://graph.microsoft.com/v1.0/directoryObjects/" + $row.id
        $body.add("@odata.id", $userRef)
        $request = @"
        $($body | ConvertTo-Json -Depth 4)
"@
    
        $uri = "https://graph.microsoft.com/v1.0/groups/" + $row.groupId + "/members/`$ref"
        
        try{
            $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $request
    
        $groupPlans = @()
        $groupPlans+=$planListRequest.value
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
        
    }
    }
    }
    
    
    