resource "azurerm_resource_group" "myrg" {
  name     = "New-RG"
  location = "West Europe"
}

#Vnet creation

resource "azurerm_virtual_network" "myvnet" {
  name                = "virtnetname"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_subnet" "sub1" {
  name                 = "inamsubnet"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

#storage account creation

resource "azurerm_storage_account" "mystg" {
  name                = "inamstg"
  resource_group_name = azurerm_resource_group.myrg.name

  location                 = azurerm_resource_group.myrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["100.0.0.1"]
    virtual_network_subnet_ids = [azurerm_subnet.sub1.id]
  }

  tags = {
    environment = "staging"
  }
}


resource "azurerm_app_service_plan" "new-app-se" {
  name = "inamappserplan"
  location = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "new-fun-app" {
  name                       = "tinam-functions"
  location                   = azurerm_resource_group.myrg.location
  resource_group_name        = azurerm_resource_group.myrg.name
  app_service_plan_id        = azurerm_app_service_plan.new-app-se.id
  storage_account_name       = azurerm_storage_account.mystg.name
  storage_account_access_key = azurerm_storage_account.mystg.primary_access_key
}

#creation of webapp

resource "azurerm_app_service" "myappservice" {
  name                = "inam-app-service"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  app_service_plan_id = azurerm_app_service_plan.new-app-se.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

}

