# OIDC auth method for interactive human login via Authentik (auth.starnix.net).
#
# The mount itself (auth/oidc) and its config -- oidc_discovery_url, client id,
# and especially oidc_client_secret -- are managed outside Terraform. Vault never
# returns the client secret on read, so importing the backend config here would
# force us to keep a copy of the secret in state/config just to avoid drift. The
# role below is where the token TTL lives, so managing only the role is enough to
# control how long a login token is valid.
#
# Backend accessor auth_oidc_e4166ac3 (referenced in policies.tf).
resource "vault_jwt_auth_backend_role" "authentik_admin" {
  backend   = "oidc"
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
