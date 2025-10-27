resource "azurerm_key_vault_certificate_issuer" "oneCert" {
  name          = "OneCertPubCA"    
  key_vault_id  = var.key_vault_id
  provider_name = "OneCertV2-PublicCA"  #   DigiCert, GlobalSign, OneCertV2-PrivateCA, OneCertV2-PublicCA and SslAdminV2
#   org_id        = "oneCert"
#   account_id    = "try(var.settings.provider_name, null)0000"
#   password      = "example-password"
}