# Second KV v2 mount, separate from the primary `secret/` mount. It is currently
# EMPTY and unused -- adopted here only so it is visible in IaC. If it turns out
# to serve no purpose, removing this resource (and the mount) is the cleaner end
# state; that is a deliberate destructive change, so it is left for a follow-up.
resource "vault_mount" "kv" {
  path    = "kv"
  type    = "kv"
  options = { version = "2" }
}

import {
  to = vault_mount.kv
  id = "kv"
}
