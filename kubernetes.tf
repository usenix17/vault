# JWT auth method for the Talos cluster
# Using JWT instead of kubernetes auth because the k8s API is behind an Omni proxy
# that rejects SA bearer tokens, making the TokenReview API inaccessible from outside.
# JWT auth validates SA tokens locally using the cluster's RSA public key — no TokenReview needed.
resource "vault_jwt_auth_backend" "kubernetes" {
  type = "jwt"
  path = "kubernetes"

  # Validate SA JWTs using the cluster's RSA signing public key directly
  jwt_validation_pubkeys = [
    "-----BEGIN PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAuR128yJyw4bIUHVGcQPJ\nDWVqPApyhfIQRj7lnxQhUPJ1aYl8r9hHxka6F4jQ1kSlJGNzlo0M5ygU/gFw56RA\n8RPQK4xYGmyTnIVE2CcF2SeNzht4DtkeAkqOv9RXa885+ITtanzV1qNo+J48CeDs\nSh5coCi5GHA5RtZ+fGAyMc65jMWVVixQG95JZUXAUtwaOy5MpX+yNuJhjTW00RDT\n6TUma6xJ2xWZo5epe4pwALFhRYuH0cXZogI46FcnZgruT6I9msKTTTz6RXurrmQ/\n3id3c9PGTsVjdABmx/N7EQ0ddWmhD3hUf/IekLLvfJxhF8a46MkHbeJj8WZ7xTop\nijujfgvd9+1FHEKWwGgp6asHJMpazGzuLIrZOmzYEuNHCyLseij374PfuOFkk+90\nwoUBY0/yA5HfZTZx1h0tP/H8BQ367FrFSXXD129f+VnqrhjOvUQucphDYCYluiBO\nFz043Z5Efj4OZ7Bt4NRjsaFumhcENZAMrOcN/OiKnwZJFVPW752tFmXbut3nfReJ\nYrGFVuhP0xFc4Im68dQ8Iz+b5RZ4LGHT/d7KqJOerJwPI9Cz3CdRCBPb6wVB6rlo\nDIdPhhFAWugRIeRb7TO5ZLPDlQHFCsCh/QtSNMCcO87Jj4g5wB/IGI3t76cxX3Hh\nxUwTkrkItRPIuTSd217Y9AcCAwEAAQ==\n-----END PUBLIC KEY-----"
  ]
}

# Policy for cluster workloads to read secrets
resource "vault_policy" "cluster_secrets_reader" {
  name = "cluster-secrets-reader"

  policy = <<-EOT
    path "secret/data/cluster/*" {
      capabilities = ["read"]
    }

    path "secret/metadata/cluster/*" {
      capabilities = ["list", "read"]
    }
  EOT
}

# Role binding: any service account in any namespace can authenticate
# Validates that the JWT was issued for audience "vault" and has a valid sub claim
resource "vault_jwt_auth_backend_role" "cluster" {
  backend        = vault_jwt_auth_backend.kubernetes.path
  role_name      = "cluster"
  token_policies = [vault_policy.cluster_secrets_reader.name]
  token_ttl      = 3600

  bound_audiences = ["vault"]
  user_claim      = "sub"
  role_type       = "jwt"
}
