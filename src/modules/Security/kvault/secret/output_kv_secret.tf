output "kvault_secret_name" {
  value = azurerm_key_vault_secret.kv-secret.name
}

output "kvault_secret_id" {
  value     = azurerm_key_vault_secret.kv-secret.id
  sensitive = false
}


output "kvault_secret_value" {
  value     = azurerm_key_vault_secret.kv-secret.value
  sensitive = true
}