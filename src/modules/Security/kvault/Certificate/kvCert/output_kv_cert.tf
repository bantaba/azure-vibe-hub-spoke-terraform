output "certName" {
  value = azurerm_key_vault_certificate.kv-testCert.name
}

output "certId" {
  value = azurerm_key_vault_certificate.kv-testCert.id
}

output "certSecretId" {
  value = azurerm_key_vault_certificate.kv-testCert.secret_id
}

output "certData" {
  value = azurerm_key_vault_certificate.kv-testCert.certificate_data
}