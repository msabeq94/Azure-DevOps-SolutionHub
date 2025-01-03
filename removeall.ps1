$TenantID = "87431d80-c13c-4f97-8d52-4bd5ec6e617e"
$Applicationid = "14c278e4-bfb7-451a-8af2-40f0c1e7675f"
$clientSecret = "J-d8Q~vvfYol.6aJoA12mI_m9YjN3ab-vp5uecDO"


$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force

#$ApplicationSecret = ($clientSecret) | ConvertTo-SecureString -AsPlainText -Force
$Credential= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Applicationid, $secureClientSecret
#Connect-AzAccount  -TenantId $TenantID -ServicePrincipal -Credential $Credential
Connect-AzureAD -TenantId $TenantID -ServicePrincipal -Credential $Credential
# Get all users whose usernames start with "devops"
$users = Get-AzureADUser -All $true | Where-Object { $_.UserPrincipalName -like "devops*" }

# Delete each user
foreach ($user in $users) {
    Remove-AzureADUser -ObjectId $user.ObjectId
    Write-Output "Deleted user: $($user.UserPrincipalName)"
}