# Identity groups that map Authentik OIDC group claims to Vault policies.
#
# These are EXTERNAL groups: membership is driven by the `groups` claim at OIDC
# login, so member_entity_ids are owned by Vault, not Terraform. We manage the
# group, its policy set, and the alias -- the alias `name` is the exact value
# Authentik emits in the groups claim, which is what maps a login into the group.

# breakglass -> ssh-root-role (members can sign root SSH certs). Already live.
resource "vault_identity_group" "breakglass" {
  name     = "breakglass"
  type     = "external"
  policies = ["ssh-root-role"]
}

resource "vault_identity_group_alias" "breakglass" {
  name           = "breakglass"
  mount_accessor = "auth_oidc_e4166ac3"
  canonical_id   = vault_identity_group.breakglass.id
}

# authentik-admins -> admin-policy. The group existed but was non-functional
# (no alias, so no login could ever match it). The alias below wires it to the
# "authentik-admins" groups-claim value. If Authentik emits a different value,
# this simply never matches (fails safe -- grants nothing) until corrected.
resource "vault_identity_group" "authentik_admins" {
  name     = "authentik-admins"
  type     = "external"
  policies = ["admin-policy"]
}

resource "vault_identity_group_alias" "authentik_admins" {
  name           = "authentik-admins"
  mount_accessor = "auth_oidc_e4166ac3"
  canonical_id   = vault_identity_group.authentik_admins.id
}

# Adopt the resources that already exist live (Terraform 1.5+ import blocks), so
# the merge-apply imports them instead of trying to create duplicates. The
# authentik-admins alias has no import block: it does not exist yet, so apply
# creates it. These blocks are safe to remove in a later cleanup once imported.
import {
  to = vault_identity_group.breakglass
  id = "473048b6-6272-417b-40ae-197523b3d269"
}

import {
  to = vault_identity_group_alias.breakglass
  id = "07e7ac10-37a0-4a56-9201-46e603f6d074"
}

import {
  to = vault_identity_group.authentik_admins
  id = "cd9d94a8-a0f8-9ae6-6dd3-b3f3cf1dec22"
}
