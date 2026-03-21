variable "token_reviewer_jwt" {
  description = "Long-lived SA token for vault-token-reviewer in kube-system, used by Vault to call the Kubernetes TokenReview API"
  type        = string
  sensitive   = true
}
