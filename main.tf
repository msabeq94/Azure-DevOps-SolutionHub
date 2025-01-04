terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.87.0"
      # subscription_id = var.customer_subscription_id
      # client_id = var.customer_client_id
      # client_secret = var.customer_client_secret
      # tenant_id = var.customer_tenant_id
    }
  }
 
  # backend "azurerm" {
  #   resource_group_name  = "DevOps-Msabeq"          # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
  #   storage_account_name = "vfdevopspcrstatefiles"                              # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
  #   container_name       = "pcrtfstate"                               # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
  #   key                  = "cststate.tfstate"                # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  #   client_id            = "d78d4e21-db81-401f-a368-032e25d575b5"  # Can also be set via `ARM_CLIENT_ID` environment variable.
  #   client_secret        = "WhJ8Q~2ZQIBsAsMJjKlgXBdnVK1FHXsmXQgIcbqD"  # Can also be set via `ARM_CLIENT_SECRET` environment variable.
  #   subscription_id      = "f5980816-b478-413b-ae0b-5fb6d820a88f"  # Can also be set via `ARM_SUBSCRIPTION_ID` environment variable.
  #   tenant_id            = "e22861cb-ba60-48a7-8d82-fa8e4267a5bd"  # Can also be set via `ARM_TENANT_ID` environment variable.
  #                                    # Can also be set via `ARM_USE_AZUREAD` environment variable.
  # }


   backend "azurerm" {
    resource_group_name  = "DevOps-Msabeq"          # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    storage_account_name = "vfdevopspcrstatefiles"                              # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "pcrtfstate"                               # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "cststate.tfstate" 
    # use_oidc             = true                # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
    client_id            = "e7dce71f-5ae8-4ae1-9c3a-c558f929f9ca"  # Can also be set via `ARM_CLIENT_ID` environment variable.
    subscription_id      = "f5980816-b478-413b-ae0b-5fb6d820a88f"  # Can also be set via `ARM_SUBSCRIPTION_ID` environment variable.
    tenant_id            = "e22861cb-ba60-48a7-8d82-fa8e4267a5bd"  # Can also be set via `ARM_TENANT_ID` environment variable.
    # use_azuread_auth     = true                                    # Can also be set via `ARM_USE_AZUREAD` environment variable.
  # }
  # backend "azurerm" {
  #   resource_group_name = "DevOps-Msabeq"
  #   storage_account_name = "vfdevopspcrstatefiles"
  #   container_name = "pcrtfstate"
  #   key = "cststate.tfstate"
  #   access_key = "StorageAccountKey"
  #}
}
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "DevOps-Msabeq"          # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
#     storage_account_name = "vfdevopspcrstatefiles"                              # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
#     container_name       = "pcrtfstate"                               # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
#     key                  = "cststate.tfstate"                # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
#     # client_id            = "00000000-0000-0000-0000-000000000000"  # Can also be set via `ARM_CLIENT_ID` environment variable.
#     # subscription_id      = "00000000-0000-0000-0000-000000000000"  # Can also be set via `ARM_SUBSCRIPTION_ID` environment variable.
#     # tenant_id            = "00000000-0000-0000-0000-000000000000"  # Can also be set via `ARM_TENANT_ID` environment variable.
#     use_azuread_auth     = true                                    # Can also be set via `ARM_USE_AZUREAD` environment variable.
#   }
}

provider "azurerm" {
  features {}
}
provider "azuread" {
  client_id = var.customer_client_id
  client_secret = var.customer_client_secret
  tenant_id = var.customer_tenant_id
}


# resource "azurerm_resource_group" "test-rg" {
#   location = var.location
#   name     = "vf-devops-${var.location}-resources"
# }
# data "azurerm_client_config" "current" {}



resource "azuread_user" "create_subscription_owner" {
  display_name = "${var.customer_subscription_owner_first_name} ${var.customer_subscription_owner_last_name}"
  password = random_password.customer_subscription_owner_password.result
  user_principal_name = "${var.customer_subscription_owner_first_name}.${var.customer_subscription_owner_last_name}@${var.domain_name}.onmicrosoft.com"
}

resource "random_password" "customer_subscription_owner_password" {
  length = 16
  special = true
  override_special = "!@#$"
  lower = true
  numeric = true
  upper = true
}

# output "customer_subscription_owner_username" {
#   value = try(azuread_user.create_subscription_owner.object_id,"Customer Subscription Owner not defined")
# }

# output "customer_subscription_owner_email" {
#   value = try(azuread_user.create_subscription_owner.user_principal_name,"Customer Subscription Owner not defined")
# }

output "customer_subscription_owner_password" {
  value = try(azuread_user.create_subscription_owner.password,"Customer Subscription Owner not defined")
  sensitive = true
  
}

output "user_principal_name" {
  value = try(azuread_user.create_subscription_owner.user_principal_name,"Customer Subscription Owner not defined")
}

#https://confluence.tools.aws.vodafone.com/display/CSAR/Microsoft+Entra+ID+Tenant+and+Azure+Subscription+Deployment+Blueprint#MicrosoftEntraIDTenantandAzureSubscriptionDeploymentBlueprint-CostControlConfiguration
/*
Section: 7.9.1. Cost Management Budgets
*/
  
# locals {
#   current_year_month = formatdate("YYYY-MM",timestamp())
# }

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/consumption_budget_subscription
# resource "azurerm_consumption_budget_subscription" "vf_core_budget" {
#   name = "vf-core-budget-alert"
#   subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#   amount = var.budget_amount
#   time_grain = "Monthly"
#   time_period {
#     start_date = "${local.current_year_month}-01T00:00:00Z"
#     end_date = timeadd("${local.current_year_month}-01T00:00:00Z", "26280h")
#   }
#   notification{
#     enabled = true
#     operator = "GreaterThanOrEqualTo"
#     threshold = "75"
#     contact_emails = [var.customer_budget_contact_email]
#   }
#   notification{
#     enabled = true
#     operator = "GreaterThanOrEqualTo"
#     threshold = "95"
#     contact_emails = [var.customer_budget_contact_email]
#   }
#   notification{
#     enabled = true
#     operator = "GreaterThanOrEqualTo"
#     threshold = "99"
#     contact_emails = [var.customer_budget_contact_email]
#   }
# }
