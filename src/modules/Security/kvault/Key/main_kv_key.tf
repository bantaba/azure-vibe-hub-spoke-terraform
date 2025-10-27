
#############################################################################
#      ###################          
#############################################################################


resource "azurerm_key_vault_key" "testKey" {  //TODO: fork to own module
  name         = var.kVaultKeyName  // "${terraform.workspace}-generated-key"
  key_vault_id = var.kVaultId // azurerm_key_vault.main-kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  expiration_date = "2022-12-31T00:00:00Z"
  tags            = var.tags                     
}
