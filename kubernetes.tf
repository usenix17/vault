# JWT auth method for the Talos cluster
# Using JWT instead of kubernetes auth because the k8s API is behind an Omni proxy
# that rejects SA bearer tokens, making the TokenReview API inaccessible from outside.
# JWT auth validates SA tokens locally using the cluster's RSA public key — no TokenReview needed.
resource "vault_jwt_auth_backend" "kubernetes" {
  type = "jwt"
  path = "kubernetes"

  # Validate SA JWTs using the cluster's RSA signing public key directly.
  #
  # ROTATION RUNBOOK: this key is pinned by hand because the cluster's JWKS
  # endpoint is not reachable from Vault (the API sits behind the Omni proxy).
  # If the Talos cluster rotates its service-account signing key, SA login here
  # breaks until this value is updated:
  #   1. Get the current JWKS (RSA key) from the cluster, e.g. from inside the
  #      cluster or via Omni: `kubectl get --raw /openid/v1/jwks`
  #   2. Convert the JWK (n, e) to a PEM SubjectPublicKeyInfo:
  #        python3 -c 'import json,base64,sys; from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers; from cryptography.hazmat.primitives.serialization import Encoding,PublicFormat; k=json.load(sys.stdin)["keys"][0]; d=lambda s:int.from_bytes(base64.urlsafe_b64decode(s+"="*(-len(s)%4)),"big"); print(RSAPublicNumbers(d(k["e"]),d(k["n"])).public_key().public_bytes(Encoding.PEM,PublicFormat.SubjectPublicKeyInfo).decode())'
  #   3. Replace the PEM below with the new one, open a PR, merge to apply.
  # (The old /root/vault-k8s-auth-update.sh on the Vault host is obsolete -- it
  # targets the pre-migration kubernetes-auth config shape. Do not use it.)
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
