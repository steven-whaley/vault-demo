terraform {
  required_version = ">= 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18"
    }
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 3.72"
    }
  }
  cloud {
    organization = "swhashi"
    workspaces {
      name = "vault-demo-azure-secrets"
    }
  }
}

provider "vault" {
  address = "http://${data.tfe_outputs.vault_demo_init.values.vault_pub_address}:8200"
  auth_login_userpass {
    username = "terraform"
    password = data.tfe_outputs.vault_demo_init.values.vault_pass
  }
}

provider "azurerm" {
  features {}

  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id

  skip_provider_registration = true
}