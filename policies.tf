resource "vault_policy" "admin" {
  name = "admin-policy"

  policy = <<-EOT
    # Manage KV secrets
    path "secret/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Allow SSH signing - ONLY default-user role
    path "ssh-client-signer/sign/default-user" {
      capabilities = ["create", "update"]
    }

    # Allow reading the SSH CA public key
    path "ssh-client-signer/config/ca" {
      capabilities = ["read"]
    }

    # Allow listing SSH roles (read-only)
    path "ssh-client-signer/roles/*" {
      capabilities = ["list", "read"]
    }

    # Token management
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "identity/entity/name/{{identity.entity.name}}" {
      capabilities = ["read"]
    }

    path "identity/entity/id/{{identity.entity.id}}" {
      capabilities = ["read"]
    }

    # UI access
    path "identity/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    path "sys/auth" {
      capabilities = ["read"]
    }

    path "sys/mounts" {
      capabilities = ["read", "list"]
    }

    path "sys/health" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_policy" "ssh_root_role" {
  name = "ssh-root-role"

  policy = <<-EOT
    # Allow signing with root-role only
    path "ssh-client-signer/sign/root-role" {
      capabilities = ["create", "update"]
    }

    # Allow listing roles to see what's available
    path "ssh-client-signer/roles/*" {
      capabilities = ["read", "list"]
    }
  EOT
}
