terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Local state for now (like the CA/PIM project's first pass). A remote
  # azurerm backend on the shared tfstate account is a planned follow-up.
}

provider "azurerm" {
  subscription_id = var.subscription_id

  # The storage account has shared-key auth disabled, so the provider must use
  # our az-login (Entra) identity for data-plane calls (blob-service polling and
  # container creation) instead of account keys. Requires the deployer to hold a
  # Storage Blob Data role (see identity.tf).
  storage_use_azuread = true

  features {
    key_vault {
      # Let `terraform destroy` fully remove the vault so the demo costs nothing
      # to tear down. Purge protection stays off (see keyvault.tf).
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  suffix   = random_string.suffix.result
  name     = "zsec"
  location = var.location

  # Globally-unique names.
  kv_name      = "kv-${local.name}-${local.suffix}" # 3-24 chars, alnum + hyphen
  storage_name = "st${local.name}${local.suffix}"   # 3-24 chars, lowercase alnum only

  tags = {
    project = "zero-secrets-workload-identity"
    managed = "terraform"
    pairs   = "aws-soc-chatbot" # sister project — same principle, different cloud
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-zero-secrets"
  location = local.location
  tags     = local.tags
}
