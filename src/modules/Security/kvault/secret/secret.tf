
#############################################################################
#      ################### Creates       
#############################################################################

################### Creates KV Secret   
resource "azurerm_key_vault_secret" "kv-secret" {
  name            = var.vault_secret_name  // "${terraform.workspace}secret" //var.secrets
  value           = var.vault_secret_value // random_password.pwd_gen.result
  key_vault_id    = var.vault_id           // azurerm_key_vault.main-kv.id
  content_type    = "password"
  expiration_date = var.secret_expiration_date #"2022-12-31T00:00:00Z"
  tags            = var.tags
}


# resource "azurerm_key_vault_secret" "kv-adminPwd" {
#   name            = "superAdminUser" //var.secrets
#   value           = random_password.pwd_gen.result
#   key_vault_id    = azurerm_key_vault.main-kv.id
#   depends_on      = [azurerm_key_vault.main-kv]
#   content_type    = "password"
#   expiration_date = "2022-12-31T00:00:00Z"
#   //tags            = merge(var.default_tags, tomap({ "type" = "KeyVault | Secrets" }))
# }


#############################################################################
#   END 