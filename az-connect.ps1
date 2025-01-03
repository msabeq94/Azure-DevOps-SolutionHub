#Powershell
$TenantID = "d57b6fc3-6090-4c9b-a5a2-150d88d8b506"
$ApplicationId = "918af5c4-853f-4ff3-a857-f9be8fdf9e1c"
$clientSecret = "w6B8Q~N-j5MGouftfNP3wUlYhnzidfP~o3gv5bm9"
 
$ApplicationSecret = ($clientSecret) | ConvertTo-SecureString -AsPlainText -Force 
$Cred = New-Object System.Management.Automation.PsCredential($ApplicationId,$ApplicationSecret)
Connect-AzAccount -TenantId $tenantid -ServicePrincipal -Credential $cred

#CLI
az login --service-principal -u ${customer_client_id} -p ${customer_client_secret} --tenant ${customer_tenant_id}