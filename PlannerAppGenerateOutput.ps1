# Script to generate output files of group owners who are not members

# Az PowerShell module used to read the App Registration properties from KeyVault
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
# Install-Module -Name Az.KeyVault -force

Connect-AzAccount -Tenant "<AZ Tenant>" -Subscription "<subscription name>" -AuthScope KeyVault
$clientIdss = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "<secretname>").SecretValue
$clientId = ConvertFrom-SecureString -AsPlainText $clientIdss
# $clientSecret = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "<secretname>").SecretValue

# Interactive login
# Client ID is created in Azure AD under App Registration - requires Group.Read.All and the default User.Read and Task.Read.All to get Plans
# Redirect Url is Mobile and Desktop applications - https://login.microsoftonline.com/common/oauth2/nativeclient
# Change TenantId to your own tenant 
$tenantId          = "<tenant id>" 

# Connect-MgGraph command
# Cetificate name appears to need CN= at the start - name can be found via PowerShell too
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateName "<certname>"
Get-mgContext

#################################################
# Get Groups
#################################################

Get-Date -Format "HH:mm:ss"
$groups = Get-MgGroup -All -ConsistencyLevel eventual -Count groupCount -Filter "groupTypes/any (c:c eq 'Unified')" -OrderBy DisplayName
Write-Host "There are $groupCount unified groups in the tenant" -ForegroundColor Green
Get-Date -Format "HH:mm:ss"
$groups | Export-Csv -Path ./AllUnifiedGroups.csv -NoTypeInformation

#################################################
# Output Group owners who are not members
#################################################
# counter is used to count up to number of groups per batch (500)
# fileindex used for naming files and looping
# Get-Date command just used to check timings
$counter = 0
$fileIndex = 1

Get-Date -Format "HH:mm:ss"

foreach ($group in $groups){
$counter++
# List plans
if ($counter -eq 1){
    $results = @()
}
    # Checking all groups, not just ones with plans - set loop to $true - commented out next lines    
    # $groupPlans = @()
    # $groupPlans = Get-MgGroupPlannerPlan -GroupId $group.Id
    
    
    if ($true){
  
# Get Owners in this Group

# Read Owners
$owners = @()
$owners += Get-MgGroupOwner -GroupId $group.Id

# Get Member in this Group

# Read members - need to account for no members so start with an empty array
$members = @()
$members += Get-MgGroupMember -GroupId $group.Id

###############################
# Which Owners are not members?
###############################


$ownersNotMembers = Compare-Object -ReferenceObject $owners -DifferenceObject $members -Property id | Where-Object {$_.SideIndicator -eq "<="}
If($ownersNotMembers.Count){
    $results += $ownersNotMembers | Select-Object *, @{Name="GroupId"; Expression={$group.Id}},@{Name="GroupCreated"; Expression={$group.createdDateTime}},@{Name="GroupDisplayName"; Expression={$group.displayName}}

}
#end for plan loop
    }
# Check if we have a batch
if ($counter -eq 500 -or $group -eq $groups[-1]) {
    Get-Date -Format "HH:mm:ss"
    Write-Output "Adding DisplayNames"
    # Format the file name with leading zeros
    $fileName = "out\Output_{0:D3}.csv" -f $fileIndex
	# Making calls to Get-MgUser to add in the displayname
    $updatedResults = @()
    foreach($row in $results){
        $user = Get-MgUser -UserId $row.id
        $row | Add-Member -MemberType NoteProperty -Name DisplayName -Value $user.DisplayName
        $updatedResults += $row
    }
    # Export the results array to a CSV file
    $updatedResults | Export-Csv -Path $fileName -NoTypeInformation

    # Reset the counter and increment the file index
    $counter = 0
    $fileIndex++
    Get-Date -Format "HH:mm:ss"
    $fileIndex
}
}

Get-Date -Format "HH:mm:ss"