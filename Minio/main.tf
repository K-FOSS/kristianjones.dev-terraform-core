terraform {
  required_providers {
    #
    # Minio
    #
    # Docs: https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs
    #
    minio = {
      source  = "aminueza/minio"
      version = "1.2.0"
    }

    #
    # Cloudflare
    #
    # Docs: https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs
    #
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "2.24.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = "2.22.1"
    }
  }
}

data "vault_generic_secret" "minio" {
  path = "keycloak/MINIO"
}

provider "minio" {
  minio_server = "tasks.StorageWeb:9000"
  minio_region = "us-east-1"

  minio_ssl = false

  minio_access_key = "${data.vault_generic_secret.minio.data["ACCESS_KEY"]}"
  minio_secret_key = "${data.vault_generic_secret.minio.data["SECRET_KEY"]}"
}

resource "minio_s3_bucket" "nextcloudcore" {
  bucket = "nextcloud-core"
  acl    = "private"
}

resource "minio_s3_bucket" "dhcpDatabaseData" {
  bucket = "dhcp-database"
  acl    = "private"
}

resource "minio_s3_bucket" "tftpData" {
  bucket = "tftp-data"
  acl    = "private"
}

resource "minio_s3_bucket" "postgresDatabase" {
  bucket = "database-postgres"
  acl    = "private"
}