# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
  required_version = ">= 1.1.0"

  backend "azurerm" {
    resource_group_name  = "TFStateRG"
    storage_account_name = "terraformbckstorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = "myPhotoRepoRG"
  location = "eastus"
}

resource "azurerm_storage_account" "mdbstg" {
  name                     = "mediabasestorageacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "mdbshr" {
  name                 = "mediabaseshare"
  storage_account_name = azurerm_storage_account.mdbstg.name
  quota                = 2048
}

resource "azurerm_storage_share_directory" "mdbshrdir" {
  name                 = "images"
  share_name           = azurerm_storage_share.mdbshr.name
  storage_account_name = azurerm_storage_account.mdbstg.name
}

resource "azurerm_service_plan" "mdbasp" {
  name                = "mediabase-ASP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "mdb" {
  name                = "mediabase"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.mdbasp.id

  site_config {
    application_stack {
      java_server         = "TOMCAT"
      java_server_version = 10
      java_version        = 17
    }

    always_on = false
  }

  storage_account {
    access_key   = azurerm_storage_account.mdbstg.primary_access_key
    account_name = azurerm_storage_account.mdbstg.name
    name         = "mdbstoragemount"
    share_name   = azurerm_storage_share.mdbshr.name
    type         = "AzureFiles"
    mount_path   = "/images/"
  }

}