terraform {
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
  address = "https://vault.starnix.net"

  # The admin-policy token cannot create child tokens, so skip that step.
  # Authenticate by setting VAULT_TOKEN in the environment:
  #   export VAULT_TOKEN=$(vault login -method=oidc -token-only 2>/dev/null)
  skip_child_token = true
}
