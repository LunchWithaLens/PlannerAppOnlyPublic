# Scripts to try out the AppOnly APIs
# Check Owners v Members in the Groups with Plans

$clientId = "Client ID Here"

# Interactive login
# Client ID is created in Azure AD under App Registration - requires Group.Read.All and the default User.Read and Task.Read.All to get Plans
# Redirect Url is Mobile and Desktop applications - https://login.microsoftonline.com/common/oauth2/nativeclient

# Change TenantId to your own tenant 
$tenantId          = "<Tenant ID here>" 

# Connect-MgGraph command
# Cetificate name appears to need CN= at the start - name can be found via PowerShell too
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateName "<CN=cert name here>"
Get-mgContext

#################################################
# Get Groups
#################################################

$groups=Get-MgGroup
Write-Host "There are $($groups.Count) groups in the tenant" -ForegroundColor Green
get
#################################################
# List Plans by Group
#################################################
$totalOwnersNotMembers = @()
foreach ($group in $groups){

# List plans

    $groupPlans = @()
    $groupPlans = Get-MgGroupPlannerPlan -GroupId $group.Id
    
    
    if ($groupPlans.Count){
        Write-Host
        Write-Host "  Group name - $($group.displayName) has $($groupPlans.Count) plans" -ForegroundColor Green
  
# Get Owners in this Group

# Read Owners
$owners = Get-MgGroupOwner -GroupId $group.Id

# Get Member in this Group

# Read members
$members = Get-MgGroupMember -GroupId $group.Id

###############################
# Which Owners are not members?
###############################


$ownersNotMembers = Compare-Object -ReferenceObject $owners -DifferenceObject $members -Property id | Where-Object {$_.SideIndicator -eq "<="}
If($ownersNotMembers.Count){
    $totalOwnersNotMembers += $ownersNotMembers | Select-Object *, @{Name="GroupId"; Expression={$group.Id}},@{Name="GroupCreated"; Expression={$group.createdDateTime}}
    Write-Host "The following Ids identify Owners who are not members" -ForegroundColor Red
    $ownersNotMembers
}
#end for plan loop
    }
#end if no plans in group
}

#end group loop

Write-Host "The full list of Groups with Owners who are not members:"

$totalOwnersNotMembers | Format-Table

############################################
# Check if the owners should be made members
############################################

If($totalOwnersNotMembers){
$answer = Read-Host "Do you want to make the owners who are not members, members too? (yes/no)"
if ($answer -eq "yes") {
foreach($row in $totalOwnersNotMembers){
    New-MgGroupMember -GroupId $row.groupId -DirectoryObjectId $row.id
        }
    }
}