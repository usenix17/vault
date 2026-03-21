# Kubernetes auth method for the Talos cluster
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "talos" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://starnix.kubernetes.na-west-1.omni.siderolabs.io"
  kubernetes_ca_cert = <<-EOT
    -----BEGIN CERTIFICATE-----
    MIIBijCCATCgAwIBAgIRALtEUjPzPrcB8E+k5ab7/Z8wCgYIKoZIzj0EAwIwFTET
    MBEGA1UEChMKa3ViZXJuZXRlczAeFw0yNTEyMjYyMzMwNTBaFw0zNTEyMjQyMzMw
    NTBaMBUxEzARBgNVBAoTCmt1YmVybmV0ZXMwWTATBgcqhkjOPQIBBggqhkjOPQMB
    BwNCAAS90BP2f1KvFLYQfuIq39+FkTu+BhIBxJf8JGTC19wZXKp8Emr7gQLBUJEq
    0AOszBWnQBswuKgigJciQ7TOfoLvo2EwXzAOBgNVHQ8BAf8EBAMCAoQwHQYDVR0l
    BBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0O
    BBYEFPm4YXEFAlpmQ5sJYH8CANwI00THMAoGCCqGSM49BAMCA0gAMEUCIQC0oBWV
    BZYfwSdaTangFTugeEIAnLlCCdbE8fz3xJozJAIgZm9GcKVAJDwca4V4riwfG6aL
    gepGsu5y3yClf42OG9s=
    -----END CERTIFICATE-----
  EOT
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
# and get the cluster-secrets-reader policy
resource "vault_kubernetes_auth_backend_role" "cluster" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cluster"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_policies                   = [vault_policy.cluster_secrets_reader.name]
  token_ttl                        = 3600
}
