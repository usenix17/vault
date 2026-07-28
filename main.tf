terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "terraform"
    key    = "vault/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://f4bee6a7808c0215d33dee04ef9da0e3.r2.cloudflarestorage.com"
    }

    # R2 doesn't support these AWS-specific checks
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "vault" {
  # Address is read from VAULT_ADDR environment variable.
  # Locally: export VAULT_ADDR=https://vault.starnix.net
  # CI:      VAULT_ADDR=http://127.0.0.1:8200 (set in workflow)
  skip_child_token = true
}
