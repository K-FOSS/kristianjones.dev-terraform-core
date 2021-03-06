terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "2.22.1"
    }
  }
}

data "vault_generic_secret" "corevault" {
  path = "keycloak/CORE_VAULT"
}


provider "vault" {
  alias = "corevault"

  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  address = "${var.VaultURL}"

  token = "${data.vault_generic_secret.corevault.data["TOKEN"]}"
}

resource "vault_identity_oidc_key" "keycloak_provider_key" {
  provider = vault.corevault
  
  name      = "keycloak"
  algorithm = "RS256"
}

resource "vault_jwt_auth_backend" "keycloak" {
  provider = vault.corevault

  path = "oidc"
  type = "oidc"

  default_role = "default"

  oidc_discovery_url = "https://keycloak.kristianjones.dev/auth/realms/KJDev"
  oidc_client_id  =  var.KeycloakModule.KJDevRealm.CoreVaultClientModule.OpenIDClient.client_id
  oidc_client_secret = var.KeycloakModule.KJDevRealm.CoreVaultClientModule.OpenIDClient.client_secret

  tune {
    audit_non_hmac_request_keys  = []
    audit_non_hmac_response_keys = []
    default_lease_ttl            = "1h"
    listing_visibility           = "unauth"
    max_lease_ttl                = "1h"
    passthrough_request_headers  = []
    token_type                   = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "default" {
  provider       = vault.corevault

  backend        = vault_jwt_auth_backend.keycloak.path

  #
  # Role
  #
  role_name      = "default"
  role_type      = "oidc"

  #
  # Token
  #
  token_ttl      = 3600
  token_max_ttl  = 3600

  bound_audiences = ["${var.KeycloakModule.KJDevRealm.CoreVaultClientModule.OpenIDClient.client_id}"]
  user_claim      = "sub"
  claim_mappings = {
    preferred_username = "username"
    email              = "email"
  }

  allowed_redirect_uris = [
      "https://corevault.kristianjones.dev/ui/vault/auth/oidc/oidc/callback",    
      "https://corevault.kristianjones.dev/oidc/callback"
  ]
  groups_claim = format("/resource_access/%s/roles", var.KeycloakModule.KJDevRealm.CoreVaultClientModule.OpenIDClient.client_id)
}

data "vault_policy_document" "reader_policy" {
  provider = vault.corevault
  rule {
    path         = "/secret/*"
    capabilities = ["list", "read"]
  }
}

resource "vault_policy" "reader_policy" {
  provider = vault.corevault
  name   = "reader"
  policy = data.vault_policy_document.reader_policy.hcl
}
data "vault_policy_document" "manager_policy" {
  provider = vault.corevault

  rule {
    path         = "sys/policies/acl"
    capabilities = ["list"]
  }

  rule {
    path         = "sys/policies/acl/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    path         = "auth/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    path         = "sys/auth/*"
    capabilities = ["create", "update", "delete", "sudo"]
  }

  rule {
    path         = "sys/auth"
    capabilities = ["read"]
  }

  rule {
    path         = "secret/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    path         = "sys/mounts/*"
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  rule {
    path         = "sys/mounts"
    capabilities = ["read"]
  }
}

resource "vault_policy" "manager_policy" {
  provider = vault.corevault
  name   = "management"
  policy = data.vault_policy_document.manager_policy.hcl
}

resource "vault_identity_oidc_role" "CoreVaultManagementRole" {
  provider = vault.corevault

  name = "management"
  key  = vault_identity_oidc_key.keycloak_provider_key.name
}

resource "vault_identity_group" "CoreVaultManagementGroup" {
  provider = vault.corevault

  name     = vault_identity_oidc_role.CoreVaultManagementRole.name
  type     = "external"

  policies = [
    vault_policy.manager_policy.name
  ]
}

resource "vault_identity_group_alias" "management_group_alias" {
  provider = vault.corevault

  name           = "management"
  mount_accessor = vault_jwt_auth_backend.keycloak.accessor
  canonical_id   = vault_identity_group.CoreVaultManagementGroup.id
}

#
# Hashicorp Vault Unseal
#

data "vault_policy_document" "VaultTransit" {
  provider = vault.corevault

  rule {
    path         = "transit/encrypt/autounseal"
    capabilities = ["update"]
  }

  rule {
    path         = "transit/decrypt/autounseal"
    capabilities = ["update"]
  }
}

resource "vault_policy" "VaultTransitPolicy" {
  provider = vault.corevault

  name   = "VaultTransit"

  policy = data.vault_policy_document.VaultTransit.hcl
}

resource "vault_token" "VaultTransit" {
  provider = vault.corevault

  policies = ["${vault_policy.VaultTransitPolicy.name}"]

  renewable = true
}