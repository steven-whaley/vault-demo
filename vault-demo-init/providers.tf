terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "swhashi"
    workspaces {
      name = "vault-demo-init"
    }
  }
}

provider "aws" {
  region = var.region
}