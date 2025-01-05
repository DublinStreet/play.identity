variable "app_name" {
  type = string  
  description = "The name of the application and resource group"
}

variable "namespace" {
  type = string  
  description = "The name of the managed identity and namespace"
}

variable "tenant_id" {
  type = string  
  description = "The tenant id of the Azure AD"
}

variable "resource_group_name" {
  type = string  
  description = "The name of the resource group"
}

variable "location" {
  type = string  
  description = "The Azure region to deploy resources"  
}

variable "key_vault_name" {
  type = string  
  description = "The name of the key vault"
}


terraform { 
  required_providers { 
    azurerm = { 
      source = "hashicorp/azurerm" 
      version = "~> 3.0" 
    } 
  } 
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}


data "azurerm_kubernetes_cluster" "yes" { 
  name = var.app_name 
  resource_group_name = var.resource_group_name 
} 
output "aks_oidc_issuer_url" { value = data.azurerm_kubernetes_cluster.yes.oidc_issuer_url }


resource "azurerm_user_assigned_identity" "id" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.namespace
}


data "azurerm_key_vault" "kv" {
  name = var.key_vault_name
  resource_group_name = var.resource_group_name
}


resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = data.azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.id.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}