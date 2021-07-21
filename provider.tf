# Azure Provider source and version.
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "655d0f90-8754-4202-bbf3-5270b47e7a55"
  client_id       = "73b67d3f-d24a-4105-9a2a-f09f076ae700"
  client_secret   = var.client_secret
  tenant_id = "103f56da-bf53-4bd6-8e7c-49a7a9f7f20a"
}

