# SSH client-cert signing (the CA that signs SSH certs for *.starnix.net hosts).
#
# The ssh-client-signer mount and its CA key are bootstrap artifacts managed
# outside Terraform: the CA private key was generated inside Vault and can never
# be exported, so there is nothing for Terraform to own. The signing *roles*
# below are the access-control surface -- they decide who may sign a cert and for
# which principals -- so those are worth codifying and reviewing.
#
# admin-policy grants sign/default-user; the ssh-root-role policy (attached via
# the breakglass OIDC group) grants sign/root-role.

# Break-glass: sign a cert with principal "root". 1h TTL, no auto-renew.
resource "vault_ssh_secret_backend_role" "root_role" {
  backend  = "ssh-client-signer"
  name     = "root-role"
  key_type = "ca"

  allow_user_certificates = true
  allowed_users           = "root"
  default_extensions      = { "permit-pty" = "" }

  ttl                 = "3600"
  not_before_duration = "30"
}

# Everyday login: users may only sign a cert for their own username, pinned to
# the OIDC alias name via templating (mount accessor auth_oidc_e4166ac3).
resource "vault_ssh_secret_backend_role" "default_user" {
  backend  = "ssh-client-signer"
  name     = "default-user"
  key_type = "ca"

  allow_user_certificates = true
  allowed_users           = "{{identity.entity.aliases.auth_oidc_e4166ac3.name}}"
  allowed_users_template  = true
  default_extensions = {
    "permit-pty"     = ""
    "permit-user-rc" = ""
  }

  not_before_duration = "30"
}
