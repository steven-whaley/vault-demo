terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18"
    }
  }
  cloud {
    organization = "swhashi"
    workspaces {
      name = "vault-demo-ad-secrets"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "vault" {
    address = "http://${data.tfe_outputs.vault_demo_init.values.vault_pub_address}:8200"
    auth_login_userpass {
      username = "terraform"
      password = data.tfe_outputs.vault_demo_init.values.vault_pass
    }
}