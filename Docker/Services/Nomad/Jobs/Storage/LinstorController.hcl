job "linstor-controller" {
  datacenters = ["core0site1"]
  type = "service"

  group "linstor-controller" {
    network {
      mode = "bridge"

      dns {
        searches = ["core0.site1.kristianjones.dev"]
      }
      # port "linstor-api" { (2)
      #   static = 3370
      #   to = 3370
      # }
    }

    service {
      name = "linstor-api"
      port = "3370"

      connect {
        sidecar_service {}
      }

      check {
        expose = true
        type = "http"
        name = "api-health"
        path = "/health"
        interval = "30s"
        timeout = "5s"
      }
    }

    task "linstor-controller" {
      driver = "docker"
      config {
        image = "kvaps/linstor-controller:v1.14.0"

        extra_hosts = [
          "node0:172.31.245.10",
          "node1:172.31.245.11",
          "node2:172.31.245.12",
          "node3:172.31.245.13"
        ]

        mount {
          type = "bind"
          source = "local"
          target = "/etc/linstor"
        }
      }

      # template { (6)
      #  destination = "local/linstor.toml"
      #  data = <<EOH
      #    [db]
      #    user = "example"
      #    password = "example"
      #    connection_url = "jdbc:postgresql://postgres.internal.example.com/linstor"
      #  EOH
      # }

      resources {
        cpu    = 500
        memory = 700
      }
    }
  }
}