# Prerquistes || run fist time only

#Install-Module -Name az.accounts  -scope currentuser -Force  -AllowClobber  -RequiredVersion "2.12.1"
#Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser  -Force  -AllowClobber
#Install-Module Microsoft.Graph.Applications -Scope CurrentUser  -Force  -AllowClobber
#Set-ExecutionPolicy Bypass -Scope CurrentUser
#Import-module -Name az.accounts
#Import-module -Name Microsoft.Graph.Identity.DirectoryManagement
#Import-Module Microsoft.Graph.Applications
<#Install-Module -Name az.accounts  -scope currentuser -Force  -AllowClobber  -RequiredVersion "2.16.0"
 
Install-Module -Name Az.Resources  -scope currentuser -Force  -AllowClobber  -RequiredVersion "6.16.0"
 
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser  -Force  -AllowClobber -RequiredVersion "2.15.0"
 
 
Install-Module Microsoft.Graph.Applications -Scope CurrentUser  -Force  -AllowClobber -RequiredVersion "2.15.0"#>



# ==============================================================================================================================================#
# Select the OpCo
# ==============================================================================================================================================#
cls
$OpColist  =  @{
"1"  =  "UK"
"2"  =  "IT"
"3"  =  "IE"
"4"  =  "ES"
"5"  =  "PT"
}


# Sort the options by key before displaying
$sortedOptions  =  $OpColist.GetEnumerator() | Sort-Object Name

while ($true) {
Write-Host "Please Choose the Azure Greenfield Deployment Region?"
foreach ($entry in $sortedOptions) {
Write-Host "$($entry.Key)) $($entry.Value)"
}

$choiceOpCO  =  Read-Host "Enter the number corresponding to your choice"

# Check if the user's choice exists in the list
if ($OpColist.ContainsKey($choiceOpCO)) {
$OpCo  =  $OpColist[$choiceOpCO]

Write-Host "OpCO  =  $OpCo"

$creds  =  Get-Credential

Connect-AzAccount -Credential $creds

$AADToken =   ConvertTo-SecureString -AsPlainText  (Get-AzAccessToken -ResourceTypeName MSGraph).token -Force

$accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token

$header = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

Start-Sleep -Seconds 15

Connect-MgGraph -AccessToken $AADToken

break
} else {
Write-Host "Error: Invalid choice. Please select a valid option."
}
}
# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#
# Collect AzSubscription details

$azAccount  =  Get-AzSubscription
$tenantId  =  $azAccount.TenantId
$domain  =  (Get-AzTenant).DefaultDomain
$subscriptionId  =  $azAccount.Id
$subResourceId  =  "/subscriptions/" + $azAccount.Id
$context  =  Get-AzContext
$AdminMail  =  "admin@$domain"

# Helpdesk Administrator role
#$HelpdeskID  =  "affb9e36-a736-46e9-a66b-f0bcc927188c"
$HelpdeskID = (Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "Helpdesk administrator"}).Id 
# global Administrator role
#$GAID  =   "1d0694f2-45f5-45d5-a14b-0ccd90830a7b"
$GAID = (Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "global Administrator"}).Id 
# User Admin Role
#$UAID  =  "d3cbb3b0-d671-4e79-ae62-5754f14490b4"
$UAID = (Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "User Administrator"}).Id 
# admin ID
$AdminID  =  (Get-MgUser | Where-Object {$_.userPrincipalName -eq "$AdminMail"}).Id

# ==============================================================================================================================================#
# Resource providers#
# ==============================================================================================================================================#
while ($true) {
$registerProvidersResponse  =  Read-Host "Do you want to register Providers? (yes/no)"

if ([string]::IsNullOrEmpty($registerProvidersResponse) -or $registerProvidersResponse -eq "yes" -or $registerProvidersResponse -eq "y") {
$Rproviders  =  @("Microsoft.Management","Microsoft.KeyVault","Microsoft.Network","Microsoft.Advisor","Microsoft.Storage","Microsoft.OperationalInsights","Microsoft.PolicyInsights","Microsoft.Kusto","Microsoft.App","Microsoft.ManagedIdentity","Microsoft.Security","Microsoft.ADHybridHealthService","microsoft.insights")
foreach($Rprovider in $Rproviders){
Register-AzResourceProvider -ProviderNamespace $Rprovider

}

foreach ($Rprovider in $Rproviders) {
$RegistrationState  =  (Get-AzResourceProvider -ProviderNamespace $Rprovider).RegistrationState

while ($RegistrationState -ne "Registered") {
Start-Sleep -Seconds 5
$RegistrationState  =  (Get-AzResourceProvider -ProviderNamespace $Rprovider).RegistrationState
}

Write-Output "$Rprovider registered."
}

break
}
elseif ($registerProvidersResponse -eq "no" -or $registerProvidersResponse -eq "n") {
Write-Output "No providers registered."
break

}
else {
Write-Host "Invalid response. Please enter 'yes' or 'no'."
}
}
# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#
# Create new SPN


while ($true) {
$responseSPN  =  Read-Host "Configuring Terraform Azure AD service principal (yes/no)"

if ([string]::IsNullOrEmpty($responseSPN) -or $responseSPN -eq "yes" -or $responseSPN -eq "y") {

$appDisplayName  =  "vf-core-terraform"

$app  =  New-MgApplication -DisplayName $appDisplayName -SignInAudience "AzureADMyOrg" -RequiredResourceAccess @(
@{
ResourceAppId  =  "00000003-0000-0000-c000-000000000000"
ResourceAccess  =  @(
@{
Id    =  "09850681-111b-4a89-9bed-3f2cae46d706"
Type  =  "Role"
},
@{
Id    =  "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
Type  =  "Scope"
}
)
},
@{
ResourceAppId  =  "797f4846-ba00-4fd7-ba43-dac1f8f63013"
ResourceAccess  =  @(
@{
Id    =  "41094075-9dad-400e-a0bd-54e686782033"
Type  =  "Scope"
}
)
}
)


$sp  =  New-MgServicePrincipal -BodyParameter @{
"appId"  =  $app.AppId
}

$spnAppId  =  $app.AppId

#Start-Sleep -Seconds 30

New-MgDirectoryRoleMemberByRef -DirectoryRoleId $GAID -BodyParameter @{"@odata.id"  =  "https://graph.microsoft.com/v1.0/directoryObjects/$($sp.Id)"}
#New-MgDirectoryRoleMemberByRef -DirectoryRoleId $GAID -BodyParameter @{"@odata.id"  =  "https://graph.microsoft.com/v1.0/directoryObjects/$sp.Id"}
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Owner" -Scope $subResourceId

$secret  =  (Add-MgServicePrincipalPassword -ServicePrincipalId $sp.Id -BodyParameter @{
passwordCredential  =  @{
displayName  =  "Jenkins"
}
}).SecretText


$tokenSPN  =  [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $TenantId, $null, "Never", $null, "74658136-14ec-4630-ad9b-26e160ff0fc6")
$headerPN  =  @{
'Authorization'  =  'Bearer ' + $tokenSPN.AccessToken
'X-Requested-With' =  'XMLHttpRequest'
'x-ms-client-request-id' =  [guid]::NewGuid()
'x-ms-correlation-id'  =  [guid]::NewGuid()}

$azureApp  =  Get-AzADApplication -DisplayName $appDisplayName
$azureAppId  =  $azureApp.AppId
$urlcations =  "https://main.iam.ad.ext.azure.com/api/RegisteredApplications/$azureAppId/Consent?onBehalfOfAll = true"
Start-Sleep -Seconds 10

Invoke-RestMethod -Uri $urlcations -Headers $headerPN  -Method POST -ErrorAction Stop

# wait 30 sec
Start-Sleep -Seconds 30

# rerun Grant admin consent

Invoke-RestMethod -Uri $urlcations -Headers $headerPN  -Method POST -ErrorAction Stop

Write-Output "SPN creation completed successfully

Domain: $($domain.Split('.')[0])

subscriptionId : $subscriptionId

TenantId : $tenantId

client ID: $spnAppId

Secret : $secret"



break
}

elseif ($responseSPN -eq "no" -or $responseSPN -eq "n") {
break
}
else {
Write-Host "Invalid response. Please enter 'yes' or 'no'."
}}

# ==============================================================================================================================================#
# post-provisioning
# ==============================================================================================================================================#
while ($true) {
$responsePostP  =  Read-Host "Start with post-provisioning configuration (yes/no)"
if ([string]::IsNullOrEmpty($responsePostP) -or $responsePostP -eq "yes" -or $responsePostP -eq "y") {

$Budget  =  Read-Host "set the budget amount"
# Set variables
$RGname  =  "vf-core-$OpCo-resources-rg"
$RGLocation  =  (Get-AzResourceGroup -Name $RGname).Location
$Diagnosticname  =  "vf-core-audit-logs-aad"
$LogAnalytics  =  "vf-core-log-analytics"
$StorageAccount  =  (Get-AzStorageAccount -ResourceGroupName $RGname).StorageAccountName
$RGlocation  =  (Get-AzResourceGroup -Name $RGname).Location

# Import users
#$users  =  Import-Csv "C:\CM\PCR\Azure\users - Copy.csv"
#$users  = Import-Csv "C:\Users\OmarSabekM.VF-ROOT\Downloads\IMPRESA PASQUALUCCI 1.csv"
$users  =  Import-Csv "C:\CM\PCR\Azure\users - Copy - Copy.csv"
# $users = Import-Csv "C:\CM\PCR\Azure\users - Copy - Copy.csv"
# For $l1users
$l1users  =  $users.l1users | Where-Object {$_ -ne $null -and $_ -ne ""}
$Countl1users  =  $l1users.Count
# For $l2users
$l2users  =  $users.l2users | Where-Object {$_ -ne $null -and $_ -ne ""}
$Countl2users  =  $l2users.Count
# For $GAuser
$GAusers  =  $users.GAuser | Where-Object {$_ -ne $null -and $_ -ne ""}
$CountGAuser  =  $GAusers.Count
# For $healtemailAddresses
$healtemailAddresses  =  $users.healtemailAddresses | Where-Object {$_ -ne $null -and $_ -ne ""}
# For $securityemailAddresses
$securityemailAddresses  =  $users.securityemailAddresse | Where-Object {$_ -ne $null -and $_ -ne ""}
# For $budgetcontacts
$budgetcontacts  =  $users.budgetcontacts | Where-Object {$_ -ne $null -and $_ -ne ""}  | ConvertTo-Json

# Group ID vf-core-subscription-level1-support
$GroupObjectIdL1  =  (Get-MgGroup -Filter "DisplayName eq 'vf-core-subscription-level1-support'").id

# Group ID vf-core-subscription-level2-support
$GroupObjectIdL2  =  (Get-MgGroup -Filter "DisplayName eq 'vf-core-subscription-level2-support'").id

# Key vault settings
$KeyVaultScope  =  (Get-AzKeyVault -ResourceGroupName $RGname).ResourceId
$GroupObjectIdKey  =  (Get-MgGroup -Filter "DisplayName eq 'vf-core-keyvault-mgmt'").id

break
}
elseif ($responsePostP -eq "no" -or $responsePostP -eq "n") {
exit
}
else {
Write-Host "Invalid response. Please enter 'yes' or 'no'."
}
}
# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#
if (-not $l1users) {
Write-Output "There are no L1 users to invite."
} else {
foreach ($L1user in $l1users) {

$L1userid  =  (New-MgInvitation  -InvitedUserEmailAddress $L1user -InviteRedirectUrl "https://portal.azure.com" -SendInvitationMessage:$true).InvitedUser.Id
Start-Sleep -Seconds 5
New-MgGroupMember -GroupId $GroupObjectIdL1 -DirectoryObjectId $L1userid
Start-Sleep -Seconds 5
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $HelpdeskID -BodyParameter @{"@odata.id"  =  "https://graph.microsoft.com/v1.0/directoryObjects/$L1userid"}
Write-Output "L1 support $L1user invited "
}
Write-Output "$Countl1users L1 support users invited successfully."
}


if (-not $l2users) {
Write-Output "There are no L2 users to invite."
} else {
foreach ($L2user in $l2users) {
$L2userid  =  (New-MgInvitation  -InvitedUserEmailAddress $L2user -InviteRedirectUrl "https://portal.azure.com" -SendInvitationMessage:$true).InvitedUser.Id
Start-Sleep -Seconds 5
New-MgGroupMember -GroupId $GroupObjectIdL2 -DirectoryObjectId $L2userid
Start-Sleep -Seconds 5
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $UAID -BodyParameter @{"@odata.id"  =  "https://graph.microsoft.com/v1.0/directoryObjects/$L2userid"}
Write-Output "L2 support $L2user invited "

}
Write-Output "$Countl2users L2 support invited successfully."
}

# invite GA users

if (-not $GAusers) {
Write-Output "There are no GA users to invite."
} else {
foreach ($GAuser in $GAusers) {

$GAuserid  =  (New-MgInvitation  -InvitedUserEmailAddress $GAuser -InviteRedirectUrl "https://portal.azure.com" -SendInvitationMessage:$true).InvitedUser.Id
Start-Sleep -Seconds 5
New-MgGroupMember -GroupId $GroupObjectIdL2 -DirectoryObjectId $GAuserid
Start-Sleep -Seconds 5
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $GAID -BodyParameter @{"@odata.id"  =  "https://graph.microsoft.com/v1.0/directoryObjects/$GAuserid"}
Write-Output "GA $GAuser invited "

}
Write-Output "$CountGAuser GA users invited successfully."
}

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#

# Key Vault (IAM access)
Start-Sleep -Seconds 5

If ($OpCo  -eq "UK"){

New-AzRoleAssignment -ObjectID "1f3fbac3-31a5-4346-bec7-3e8cca6d1e77" -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID $GroupObjectIdKey -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope

Write-Output "Key Vault $OpCo (IAM access) settings updated successfully."}

elseif ($OpCo   -eq  "IT"){

New-AzRoleAssignment -ObjectID "dd89b7bf-9972-41e0-90ab-9692c9756887" -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID $GroupObjectIdKey -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope


Write-Output "Key Vault $OpCo (IAM access) settings updated successfully."}

elseif ($OpCo  -eq  "IE"){

New-AzRoleAssignment -ObjectID "e47928d8-7dd3-498f-8ceb-fa17870638c7" -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID $GroupObjectIdKey -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope

Write-Output "Key Vault (IAM access) setting updated successfully."}

elseif ($OpCo   -eq  "ES"){

New-AzRoleAssignment -ObjectID "78d91dcc-fc20-41b7-a8ad-6c12d8f6d7ff" -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID $GroupObjectIdKey -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope

Write-Output "Key Vault $OpCo (IAM access) setting updated successfully."}

elseif ($OpCo   -eq  "PT"){

New-AzRoleAssignment -ObjectID "2a5dc68f-8c5f-4c4d-87aa-fe0771ef3d4f" -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID "a0f138ea-7f3c-4b3d-a83c-4ee823e14167" -RoleDefinitionName "Key Vault Reader" -Scope $KeyVaultScope  -ObjectType "ForeignGroup"
New-AzRoleAssignment -ObjectID $GroupObjectIdKey -RoleDefinitionName "Key Vault Administrator" -Scope $KeyVaultScope

Write-Output "Key Vault $OpCo (IAM access) setting updated successfully."}

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#
Start-Sleep -Seconds 5
# vf-core-health-notifications

$healtemailReceivers  =  @()
foreach ($index in 0..($healtemailAddresses.Count - 1)) {
$healtreceiver  =  @{
"name"  =  "Health Contact $($index + 1)"
"emailAddress"  =  $healtemailAddresses[$index]
"useCommonAlertSchema"  =  $false
"status"  =  "Enabled"
  }
    $healtemailReceivers += $healtreceiver
}

$healthEndpoint  =  "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/Microsoft.Insights/actiongroups/vf-core-health-notifications?api-version=2022-06-01"

$healtemail  =  $healtemailReceivers | ConvertTo-Json
$healthtags  =  (Invoke-RestMethod -Method get -Headers $header -Uri $healthEndpoint).tags | ConvertTo-Json

$healthbody  = @"
{
"id": "/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/microsoft.insights/actionGroups/vf-core-health-notifications",
"type": "Microsoft.Insights/ActionGroups",
"name": "vf-core-health-notifications",
"location": "Global",
"kind": null,
"tags": $healthtags,
"properties": {
"groupShortName": "vf-core-hlt",
"enabled": true,
"emailReceivers": $healtemail,
"smsReceivers": [],
"webhookReceivers": [],
"eventHubReceivers": [],
"itsmReceivers": [],
"azureAppPushReceivers": [],
"automationRunbookReceivers": [],
"voiceReceivers": [],
"logicAppReceivers": [],
"azureFunctionReceivers": [],
"armRoleReceivers": []
}
}
"@
Start-Sleep -Seconds 5
$healthresponse  =  Invoke-RestMethod -Method Put -Headers $header -Uri $healthEndpoint -Body $healthbody

Write-Output "vf-core-health-notifications settings updated successfully."

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#
# vf-core-security-notifications

$securityemailReceivers  =  @()

foreach ($index in 0..($securityemailAddresses.Count - 1)) {
$securityreceiver  =  @{
"name"  =  "Security Contact $($index + 1)"
"emailAddress"  =  $securityemailAddresses[$index]
"useCommonAlertSchema"  =  $false
"status"  =  "Enabled"
   }
    $securityemailReceivers += $securityreceiver
}

$securityEndpoint  =  "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/microsoft.insights/actionGroups/vf-core-security-notifications?api-version=2022-06-01"

$securityemail  =  $securityemailReceivers | ConvertTo-Json
$securitytags  =  (Invoke-RestMethod -Method get -Headers $header -Uri $securityEndpoint).tags | ConvertTo-Json
$securitycontactsMDC  =  $securityemailAddresses -join ";"
Set-AzSecurityContact -Name "default" -Email $securitycontactsMDC -AlertAdmin -NotifyOnAlert

$securitybody  = @"
{
"id": "/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/microsoft.insights/actionGroups/vf-core-security-notifications",
"type": "Microsoft.Insights/ActionGroups",
"name": "vf-core-security-notifications",
"location": "Global",
"kind": null,
"tags": $securitytags ,
"properties": {
"groupShortName": "vf-core-cis",
"enabled": true,
"emailReceivers": $securityemail,
"smsReceivers": [],
"webhookReceivers": [],
"eventHubReceivers": [],
"itsmReceivers": [],
"azureAppPushReceivers": [],
"automationRunbookReceivers": [],
"voiceReceivers": [],
"logicAppReceivers": [],
"azureFunctionReceivers": [],
"armRoleReceivers": []
}
}
"@
Start-Sleep -Seconds 5
$securityresponse  =  Invoke-RestMethod -Method Put -Headers $header -Uri $securityEndpoint -Body $securitybody

Write-Output "vf-core-security-notifications settings updated successfully."

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#

# Set budget notifications

# Set the API endpoint for creating the Budget
$BudgetapiEndpoint  =  "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Consumption/budgets/vf-core-budget-alert?api-version=2023-05-01"

$startdate  =  (get-date -Day 1).tostring('yyyy-MM-dd'+"T"+"00:00:00Z")
$enddate  =  (([datetime]$startdate).AddHours(26280)).tostring('yyyy-MM-dd'+"T"+"00:00:00Z")

$budgetbody  =  @"
{
"id": "/subscriptions/$subscriptionId/providers/Microsoft.Consumption/budgets/vf-core-budget-alert",
"name": "vf-core-budget-alert",
"type": "Microsoft.Consumption/budgets",
"properties": {
"timePeriod": {
"startDate": "$startdate",
"endDate": "$enddate"
},
"timeGrain": "Monthly",
"amount": $Budget,
"currentSpend": {
"amount": 0.0,
"unit": "USD"
},
"category": "Cost",
"notifications": {
"actual_GreaterThan_75_Percent": {
"enabled": true,
"operator": "GreaterThan",
"threshold": 75.00,
"contactEmails":
$budgetcontacts,
"contactRoles": [],
"contactGroups": [],
"thresholdType": "Actual"
},
"actual_GreaterThan_95_Percent": {
"enabled": true,
"operator": "GreaterThan",
"threshold": 95.00,
"contactEmails":
$budgetcontacts,
"contactRoles": [],
"contactGroups": [],
"thresholdType": "Actual"
},
"actual_GreaterThan_99_Percent": {
"enabled": true,
"operator": "GreaterThan",
"threshold": 99.00,
"contactEmails":
$budgetcontacts,
"contactRoles": [],
"contactGroups": [],
"thresholdType": "Actual"
}
},
"filter": {}
}
}
"@

Start-Sleep -Seconds 5
$Budgetresponse  =  Invoke-RestMethod -Method PUT -Headers $header -Uri $BudgetapiEndpoint -Body $budgetbody -ContentType "application/json"

Write-Output "budget notifications settings created successfully."

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#

# Set Entra Diagnostic settings

# Set the API endpoint for creating the diagnostic settings
$EntraapiEndpoint  =  "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/vf-core-audit-logs-aad?api-version=2017-04-01-preview"


$Entrabody  =  @"
{
"properties": {
"logs": [

{ "category": "AuditLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "ProvisioningLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "NonInteractiveUserSignInLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "RiskyUsers",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "UserRiskEvents",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "NetworkAccessTrafficLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "RiskyServicePrincipals",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "ServicePrincipalRiskEvents",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "EnrichedOffice365AuditLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},
{
"category": "MicrosoftGraphActivityLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},


{
"category": "ServicePrincipalSignInLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},

{
"category": "ManagedIdentitySignInLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},

{
"category": "ADFSSignInLogs",
"enabled": true,
"retentionPolicy": {
"days": 0,
"enabled": false
}
},




],
"metrics": [],


"storageAccountId": "/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/Microsoft.Storage/storageAccounts/$StorageAccount",
"workspaceId": "/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/Microsoft.OperationalInsights/workspaces/$LogAnalytics"


}

}
"@
Start-Sleep -Seconds 5
$Entraresponse  =  Invoke-RestMethod -Uri $EntraapiEndpoint -Headers $header -Method Put -Body $Entrabody

Write-Output "Diagnostic settings created successfully."

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#

# continiousexport

$ContiniousExportEndpoint  =  "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$RGname/providers/Microsoft.Security/automations/ExportToWorkspace?api-version=2019-01-01-preview"

$ContiniousExportbody  =   @"
{
"properties": {
"description": "",
"isEnabled": true,

"scopes": [
{
"description": "scope for subscription $subscriptionId",
"scopePath": "/subscriptions/$subscriptionId"
}
],
"sources": [
{
"eventSource": "Assessments",
"ruleSets": [
{
"rules": [
{
"propertyJPath": "type",
"propertyType": "String",
"expectedValue": "Microsoft.Security/assessments",
"operator": "Contains"
},
{
"propertyJPath": "properties.metadata.severity",
"propertyType": "String",
"expectedValue": "medium",
"operator": "Equals"
}
]
},
{
"rules": [
{
"propertyJPath": "type",
"propertyType": "String",
"expectedValue": "Microsoft.Security/assessments",
"operator": "Contains"
},
{
"propertyJPath": "properties.metadata.severity",
"propertyType": "String",
"expectedValue": "high",
"operator": "Equals"
}
]
}
]
},
{
"eventSource": "AssessmentsSnapshot",
"ruleSets": [
{
"rules": [
{
"propertyJPath": "type",
"propertyType": "String",
"expectedValue": "Microsoft.Security/assessments",
"operator": "Contains"
},
{
"propertyJPath": "properties.metadata.severity",
"propertyType": "String",
"expectedValue": "medium",
"operator": "Equals"
}
]
},
{
"rules": [
{
"propertyJPath": "type",
"propertyType": "String",
"expectedValue": "Microsoft.Security/assessments",
"operator": "Contains"
},
{
"propertyJPath": "properties.metadata.severity",
"propertyType": "String",
"expectedValue": "high",
"operator": "Equals"
}
]
}
]
},
{
"eventSource": "SubAssessments",
"ruleSets": [
{
"rules": [
{
"propertyJPath": "properties.status.severity",
"propertyType": "String",
"expectedValue": "medium",
"operator": "Equals"
}
]
},
{
"rules": [
{
"propertyJPath": "properties.status.severity",
"propertyType": "String",
"expectedValue": "high",
"operator": "Equals"
}
]
}
]
},
{
"eventSource": "SubAssessmentsSnapshot",
"ruleSets": [
{
"rules": [
{
"propertyJPath": "properties.status.severity",
"propertyType": "String",
"expectedValue": "medium",
"operator": "Equals"
}
]
},
{
"rules": [
{
"propertyJPath": "properties.status.severity",
"propertyType": "String",
"expectedValue": "high",
"operator": "Equals"
}
]
}
]
},
{
"eventSource": "Alerts",
"ruleSets": [
{
"rules": [
{
"propertyJPath": "Severity",
"propertyType": "String",
"expectedValue": "medium",
"operator": "Equals"
}
]
},
{
"rules": [
{
"propertyJPath": "Severity",
"propertyType": "String",
"expectedValue": "high",
"operator": "Equals"
}
]
}
]
},

            {
                "eventSource": "AttackPathsSnapshot",
                "ruleSets": [
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "Medium",
                                "operator": "Equals"
                            }
                        ]
                    },
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "High",
                                "operator": "Equals"
                            }
                        ]
                    },
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "Critical",
                                "operator": "Equals"
                            }
                        ]
                    }
                ]
            },
            {
                "eventSource": "AttackPaths",
                "ruleSets": [
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "Medium",
                                "operator": "Equals"
                            }
                        ]
                    },
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "High",
                                "operator": "Equals"
                            }
                        ]
                    },
                    {
                        "rules": [
                            {
                                "propertyJPath": "attackPath.riskLevel",
                                "propertyType": "String",
                                "expectedValue": "Critical",
                                "operator": "Equals"
                            }
                        ]
                    }
                ]
            },
{
"eventSource": "SecureScores"
},
{
"eventSource": "SecureScoresSnapshot"
},
{
"eventSource": "SecureScoreControls"
},
{
"eventSource": "SecureScoreControlsSnapshot"
},
{
"eventSource": "RegulatoryComplianceAssessment"
},
{
"eventSource": "RegulatoryComplianceAssessmentSnapshot"
}
],
"actions": [
{
"workspaceResourceId": "/subscriptions/$subscriptionId/resourcegroups/$RGname/providers/microsoft.operationalinsights/workspaces/$LogAnalytics",
"actionType": "Workspace"
}
]
},

"name": "ExportToWorkspace",
"type": "Microsoft.Security/automations",
"location": "$RGLocation",
"tags": {}
}
"@
Start-Sleep -Seconds 5
$continiousexport  =  Invoke-RestMethod -Method Put -Uri $ContiniousExportEndpoint -Headers $header -Body $ContiniousExportbody -ContentType "application/json"
Write-Output "Continuous export settings created successfully."
# ==============================================================================================================================================#
# ClenUP
# ==============================================================================================================================================#



if ( $OpCo -eq "IT") {

$RemoveOwnerRole=Read-Host "remove owner role form user $adminMail ? (yes/no)"

if (([string]::IsNullOrEmpty($RemoveOwnerRole) -or $RemoveOwnerRole -eq "yes" -or $RemoveOwnerRole -eq "y") ) {

 Remove-AzRoleAssignment -ObjectId $adminID -RoleDefinitionName "Owner" -Scope "$subResourceId"

 Write-Host "owner role removed for user $adminMail"

}
elseif ($RemoveOwnerRole -eq "no" -or $RemoveOwnerRole -eq "n") {
    
  
}

 else {
    
}

}

# ==============================================================================================================================================#
# 
# ==============================================================================================================================================#

while ($true) {
$deletSPN  =  Read-Host "Delet SPN $appDisplayName (yes/no)"

if ([string]::IsNullOrEmpty($deletSPN) -or $deletSPN -eq "yes" -or $deletSPN -eq "y") {

$SPNID  =  (Get-MgServicePrincipal -Filter "DisplayName eq '$appDisplayName'").id

Remove-MgServicePrincipal -ServicePrincipalId  $SPNID

Write-Output "App Registration Deleted successfully."


break

}
elseif ($deletSPN -eq "no" -or $deletSPN -eq "n") {
break
}
else {
Write-Host "Invalid response. Please enter 'yes' or 'no'."
}}

# ==============================================================================================================================================#
# https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/disconnect-mggraph?view=graph-powershell-1.0
# ==============================================================================================================================================#
Start-Sleep -Seconds 5

while ($true) {
$logout  =  Read-Host "logout form $AdminMail (yes/no)"

if ([string]::IsNullOrEmpty($logout) -or $logout -eq "yes" -or $logout -eq "y") {

Disconnect-AzAccount -Username $AdminMail

Start-Sleep -Seconds 2

Disconnect-MgGraph

exit
}
elseif ($logout -eq "no" -or $logout -eq "n") {
exit
}
else {
Write-Host "Invalid response. Please enter 'yes' or 'no'."
}}

