terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.87.0"
      subscription_id = var.customer_subscription_id
      client_id = var.customer_client_id
      client_secret = var.customer_client_secret
      tenant_id = var.customer_tenant_id
    }
  }
  backend "azurerm" {
    resource_group_name = "DevOps-Msabeq"
    storage_account_name = "vfdevopspcrstatefiles"
    container_name = "pcrtfstate"
    key = "terraform.tfstate"
    access_key = "G7KBcye3pWrdHT1cNQ28pwQ8GY2rL2RFkIJbXXjkVqaJcWEjYD9AEm1LbOG9/KbSIFvG1ATKhfyi+AStKL1f3A=="
  }
}

# provider "azurerm" {
#   features {}
# }
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
