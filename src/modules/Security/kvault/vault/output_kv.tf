output "kvault_id" {
    value = azurerm_key_vault.main-kv.id
}

output "kvault_name" {
    value = azurerm_key_vault.main-kv.name
}

output "kvault_vault_uri" {
    value = azurerm_key_vault.main-kv.vault_uri
}