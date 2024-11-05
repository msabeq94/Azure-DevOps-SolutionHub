provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = var.customer_subscription_id
  client_id = var.customer_client_id
  client_secret = var.customer_client_secret
  tenant_id = var.customer_tenant_id
}
provider "azuread" {
  client_id = var.customer_client_id
  client_secret = var.customer_client_secret
  tenant_id = var.customer_tenant_id
}

resource "azurerm_resource_group" "test-rg" {
  location = var.location
  name     = "vf-devops-${var.location}-resources"
}
data "azurerm_client_config" "current" {}

data "azuread_user" "admin_user" {
  user_principal_name = "admin@spydertest3.onmicrosoft.com"
}
resource "azuread_group" "vf_core_subscription_owner" {
  display_name = "vf-core-subscription-owner_build_testing"
  description = "Allows the member to manage the subscription as the owner"
  owners = try([azuread_user.create_subscription_owner.object_id],[data.azurerm_client_config.current.object_id])
  members = try([azuread_user.create_subscription_owner.object_id],[])
  security_enabled = true
}
resource "azuread_user" "create_subscription_owner" {
  display_name = "ashokaaa"
  password = random_password.customer_subscription_owner_password.result
  user_principal_name = "ashokaaa.maurya@spydertechuk.onmicrosoft.com"
}

resource "random_password" "customer_subscription_owner_password" {
  length = 16
  special = true
  override_special = "!@#$"
  lower = true
  numeric = true
  upper = true
}

output "customer_subscription_owner_username" {
  value = try(azuread_user.create_subscription_owner.object_id,"Customer Subscription Owner not defined")
}

output "customer_subscription_owner_email" {
  value = try(azuread_user.create_subscription_owner.user_principal_name,"Customer Subscription Owner not defined")
}

output "customer_subscription_owner_password" {
  value = try(azuread_user.create_subscription_owner.password,"Customer Subscription Owner not defined")
  sensitive = true
}


#https://confluence.tools.aws.vodafone.com/display/CSAR/Microsoft+Entra+ID+Tenant+and+Azure+Subscription+Deployment+Blueprint#MicrosoftEntraIDTenantandAzureSubscriptionDeploymentBlueprint-CostControlConfiguration
/*
Section: 7.9.1. Cost Management Budgets
*/
  
locals {
  current_year_month = formatdate("YYYY-MM",timestamp())
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/consumption_budget_subscription
resource "azurerm_consumption_budget_subscription" "vf_core_budget" {
  name = "vf-core-budget-alert"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  amount = var.budget_amount
  time_grain = "Monthly"
  time_period {
    start_date = "${local.current_year_month}-01T00:00:00Z"
    end_date = timeadd("${local.current_year_month}-01T00:00:00Z", "26280h")
  }
  notification{
    enabled = true
    operator = "GreaterThanOrEqualTo"
    threshold = "75"
    contact_emails = [var.customer_budget_contact_email]
  }
  notification{
    enabled = true
    operator = "GreaterThanOrEqualTo"
    threshold = "95"
    contact_emails = [var.customer_budget_contact_email]
  }
  notification{
    enabled = true
    operator = "GreaterThanOrEqualTo"
    threshold = "99"
    contact_emails = [var.customer_budget_contact_email]
  }
}
