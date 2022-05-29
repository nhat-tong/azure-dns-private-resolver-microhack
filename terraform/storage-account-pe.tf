resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

resource "azurerm_storage_account" "sa" {
    name = "spoke01-${random_string.random.result}-sa"
    location = azurerm_resource_group.spoke01-rg.location
    resource_group_name = azurerm_resource_group.spoke01-rg.name

    account_tier = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "spoke01-sa-pe" {
    name = "spoke01-${random_string.random.result}-sa-endpoint"
    location = azurerm_resource_group.spoke01-rg.location
    resource_group_name = azurerm_resource_group.spoke01-rg.name
    subnet_id           = azurerm_subnet.spoke01-default-subnet.id

    private_service_connection {
        name = "spoke01-${random_string.random.result}-sa-privateserviceconnection"
        private_connection_resource_id = azurerm_storage_account.sa
        subresource_names = [ "blob" ]
        is_manual_connection = false
    }

    private_dns_zone_group {
      name                 = "private-dns-zone-group-sa"
      private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_blob_private_zone.id]
    }
}