terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.14.0"
    }

    minio = {
      source  = "aminueza/minio"
      version = "1.2.0"
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

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_plugin" "s3core-storage" {
  name                  = "rexray/s3fs"
  alias                 = "s3core-storage"
  enabled               = true
  grant_all_permissions = true
  force_destroy         = true
  enable_timeout        = 300
  force_disable         = true
  env = [
    "S3FS_OPTIONS=allow_other,use_path_request_style,nonempty,url=${var.minioURL}",
    "S3FS_ENDPOINT=${var.minioURL}",
    "S3FS_ACCESSKEY=${data.vault_generic_secret.minio.data["ACCESS_KEY"]}",
    "S3FS_SECRETKEY=${data.vault_generic_secret.minio.data["SECRET_KEY"]}"
  ]
}

data "docker_network" "storageIntWeb" {
  name = "storageIntWeb"
}

data "docker_network" "coreAuthWeb" {
  name = "authWeb"
}

resource "docker_image" "mariadb" {
  provider = docker
  name         = "kristianfjones/mariadb:vps1-core"
  keep_locally = true
}

resource "docker_container" "DHCPDatabase" {
  name    = "dhcpDatabase"
  image   = "mariadb:10"

  networks_advanced {
    name = data.docker_network.storageIntWeb.id

    aliases = ["DHCPMariaDB"]
  }

  volumes {
    volume_name    = "${var.NextCloudBucket.bucket}"
    container_path = "/var/lib/mysql"
    read_only      = false
  }

  env = [
    "MYSQL_ROOT_PASSWORD=password/",
    "MYSQL_DATABASE=DHCP",
    "MYSQL_USER=dhcp",
    "MYSQL_PASSWORD=password"
  ]
}

# resource "docker_service" "postgresDatabase" {
#   name = "postgres-database"

#   task_spec {
#     container_spec {
#       image = "postgres:alpine3.14"

#       hostname = "pgdatabase"

#       user   = "root"

#       env = {
#         POSTGRES_PASSWORD = "helloWorld"
#       }

#       mounts {
#         target    = "/var/lib/postgresql/data"
#         source    = "${var.PostgresDatabaseBucket.bucket}"
#         type      = "volume"
#       }

#       stop_signal       = "SIGTERM"
#       stop_grace_period = "10s"
#     }

#     placement {
#       max_replicas = 1
#     }

#     force_update = 0
#     runtime      = "container"
#     networks     = [data.docker_network.coreAuthWeb.id]
#   }

#   mode {
#     replicated {
#       replicas = 1
#     }
#   }

#   update_config {
#     parallelism       = 1
#     delay             = "10s"
#     failure_action    = "pause"
#     monitor           = "5s"
#     max_failure_ratio = "0.1"
#     order             = "start-first"
#   }

#   rollback_config {
#     parallelism       = 2
#     delay             = "5ms"
#     failure_action    = "pause"
#     monitor           = "10h"
#     max_failure_ratio = "0.9"
#     order             = "stop-first"
#   }

#   endpoint_spec {
#     mode = "dnsrr"
#   }
# }