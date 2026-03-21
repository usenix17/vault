# vault-terraform

Terraform configuration for managing [HashiCorp Vault](https://vault.starnix.net) at Starnix.

## What's managed

| File | Resources |
|------|-----------|
| `policies.tf` | `admin-policy`, `ssh-root-role` ACL policies |
| `kubernetes.tf` | Kubernetes auth method, Talos cluster config, `cluster-secrets-reader` policy and role |

## State backend

State is stored in Cloudflare R2 at `terraform/vault/terraform.tfstate`. Credentials are provided via `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables (R2 is S3-compatible).

## Authentication

The Vault provider authenticates via `VAULT_TOKEN`. The token must have sufficient permissions to manage policies and auth methods (i.e. a root token or a token with `sys/policies/acl/*` and `sys/auth/*` access).

```bash
# Log in via OIDC and capture the token
export VAULT_TOKEN=$(vault login -method=oidc -token-only 2>/dev/null)

# Or use the root token on the vault server
export VAULT_TOKEN=$(cat /root/.vault-token)
```

## Local usage

```bash
export VAULT_ADDR=https://vault.starnix.net
export VAULT_TOKEN=<your-token>
export AWS_ACCESS_KEY_ID=<r2-access-key>
export AWS_SECRET_ACCESS_KEY=<r2-secret-key>

terraform init
terraform plan
terraform apply
```

## CI/CD

GitHub Actions workflows run on a **self-hosted runner** on the Vault server, connecting to Vault via `http://127.0.0.1:8200` to bypass Cloudflare.

| Workflow | Trigger | Action |
|----------|---------|--------|
| `apply.yml` | Push to `master` | `terraform apply -auto-approve` |
| `plan.yml` | Pull request to `master` | `terraform plan`, posts output as PR comment |

### Required GitHub Actions secrets

| Secret | Description |
|--------|-------------|
| `VAULT_TOKEN` | Vault token with admin privileges |
| `AWS_ACCESS_KEY_ID` | Cloudflare R2 access key |
| `AWS_SECRET_ACCESS_KEY` | Cloudflare R2 secret key |

## Kubernetes secret store

The Vault Secrets Operator (VSO) is deployed to the Talos cluster via ArgoCD. Any pod can authenticate to Vault using its Kubernetes service account and read secrets from `secret/cluster/<app>`.

### Creating a secret

```bash
# Write a secret to Vault
vault kv put secret/cluster/my-app \
  username="admin" \
  password="hunter2"
```

### Consuming a secret in Kubernetes

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: my-app-secret
  namespace: my-app
spec:
  type: kv-v2
  mount: secret
  path: cluster/my-app
  destination:
    name: my-app-secret   # name of the Kubernetes Secret to create
    create: true
  refreshAfter: 1h
```

VSO will create and keep the Kubernetes `Secret` in sync with Vault automatically.
