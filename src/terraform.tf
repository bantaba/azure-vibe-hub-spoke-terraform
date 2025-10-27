#############################################################################
# TERRAFORM CONFIG
#############################################################################

terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.65,<=3.68" # "=v3.68"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}


