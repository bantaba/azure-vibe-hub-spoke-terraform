
resource "azurerm_key_vault_certificate" "kv-testCert" {  
  name         = var.kvCertName #"${terraform.workspace}Cert"
  key_vault_id = var.kvId  #azurerm_key_vault.main-kv.id
  certificate_policy {
    issuer_parameters {
      name = var.certIssuer
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties { # provider_name = try(var.settings.provider_name, null)
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names { //TODO: pass as var
        dns_names = var.san_dnsNames
      }

      subject            = var.subject # "CN=${terraform.workspace}-cert"
      validity_in_months = var.validityInMonths # 12
    }
  }
  # content_type    = "Certificate"
  # expiration_date = "2022-12-31T00:00:00Z"
  tags = var.tags # merge(var.default_tags, tomap({ "type" = "KeyVault-${terraform.workspace}-Certificates" }))
}

#############################################################################
#   END 