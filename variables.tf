variable "oidc_client_secret" {
  description = <<-EOT
    Authentik OIDC provider client secret for the Vault application. Vault never
    returns this on read, so it must be supplied here to manage the oidc auth
    backend safely -- otherwise any future apply would blank it and break login.
    Set via TF_VAR_oidc_client_secret (GitHub Actions secret OIDC_CLIENT_SECRET).
  EOT
  type        = string
  sensitive   = true
}
