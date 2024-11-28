# Variable for your Key Vault name
key_vault_name="vf-core-devops-pcr-kv"

# Get the list of secrets
secrets=$(az keyvault secret list --vault-name "$key_vault_name" --query "[].id" -o tsv)

# Loop through each secret and delete
for secret in $secrets; do
    az keyvault secret delete --id "$secret"
done

# List all users whose display name starts with 'devops'
users=$(az ad user list --query "[?starts_with(displayName, 'devops')].[objectId]" -o tsv)

# Loop through the list and delete each user
for user in $users; do
    az ad user delete --id $user
done




