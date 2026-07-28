# OIDC auth method for interactive human login via Authentik (auth.starnix.net).
# Backend accessor auth_oidc_e4166ac3 (referenced in policies.tf, groups.tf, ssh.tf).
#
# oidc_client_secret is supplied via var.oidc_client_secret because Vault never
# returns it on read. On import the provider sees an empty secret, so the first
# apply rewrites it to the real value (identical to live -- no login disruption).
# Without the variable, a future apply would blank the secret and break login.
resource "vault_jwt_auth_backend" "oidc" {
  path = "oidc"
  type = "oidc"

  oidc_discovery_url = "https://auth.starnix.net/application/o/vault/"
  oidc_client_id     = "aaF8zMmwvD9BGkHitLboavRg14SG4mTq4FgwIa2G"
  oidc_client_secret = var.oidc_client_secret
  default_role       = "authentik-admin"
}

# Adopt the existing live mount instead of creating a duplicate.
import {
  to = vault_jwt_auth_backend.oidc
  id = "oidc"
}

resource "vault_jwt_auth_backend_role" "authentik_admin" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "authentik-admin"
  role_type = "oidc"

  # 8h login token (was 3600 / 1h). Mount max_lease_ttl is 32d, so this is fine.
  token_ttl      = 28800
  token_policies = ["admin-policy", "default"]

  user_claim   = "preferred_username"
  groups_claim = "groups"

  bound_audiences = ["aaF8zMmwvD9BGkHitLboavRg14SG4mTq4FgwIa2G"]
  oidc_scopes     = ["openid", "profile", "email"]

  allowed_redirect_uris = [
    "https://vault.starnix.net/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}
