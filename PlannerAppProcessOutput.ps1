# Script to process output files of owners who are not members

# Az PowerShell module used to read the App Registration properties from KeyVault
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
# Install-Module -Name Az.KeyVault -force

Connect-AzAccount -Tenant "<tenant id>" -Subscription "<Subscription Name>" -AuthScope KeyVault
$clientIdss = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "<Secretname>").SecretValue
$clientId = ConvertFrom-SecureString -AsPlainText $clientIdss
# $clientSecret = (Get-AzKeyVaultSecret -VaultName "<vaultname>" -SecretName "secretname").SecretValue

# Interactive login
# Client ID is created in Azure AD under App Registration - requires Group.Read.All and the default User.Read and Task.Read.All to get Plans
# and GroupMember.ReadWrite.All to make edits
# Redirect Url is Mobile and Desktop applications - https://login.microsoftonline.com/common/oauth2/nativeclient
# Change TenantId to your own tenant 
$tenantId          = "<tenant id>" 

# Connect-MgGraph command
# Cetificate name appears to need CN= at the start - name can be found via PowerShell too
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateName "<cert name>"
Get-mgContext

############################################
# Get Files 1 by 1 and process
############################################
$csvFiles = Get-ChildItem "out\" -Filter *.csv 
foreach ($csvFile in $csvFiles){
    Get-Date -Format "HH:mm:ss"
    $csvData = Import-Csv -Path $csvFile.FullName

    foreach ($row in $csvData){
        New-MgGroupMember -GroupId $row.groupId -DirectoryObjectId $row.id
    }
}


