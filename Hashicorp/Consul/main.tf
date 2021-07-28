terraform {
  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "2.12.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = "2.22.1"
    }
  }
}

resource "vault_policy" "consulConnectCA" {
  name = "consul-connect-ca"

  policy = file("${path.module}/ConsulCA.hcl")
}

resource "vault_token" "consulConnectCAToken" {
  policies = ["${vault_policy.consulConnectCA.name}"]

  renewable = true
  ttl = "168h"
}

provider "consul" {
  address    = "${var.consulHostname}:${var.consulPort}"
  datacenter = "dc1"

  scheme = "https"
}

resource "consul_certificate_authority" "connect" {
  connect_provider = "vault"

  config = {
    address = "https://vault.kristianjones.dev"
    token = "${vault_token.consulConnectCAToken.client_token}"
    root_pki_path = "/connect_root/"
    intermediate_pki_path = "/connect_inter/"
  }
}