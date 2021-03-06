log_level = "${LogLevel}"

data_dir = "/Data"

name = ""

consul {
  #
  # Consul Connection
  #
  address = "${Consul.Hostname}:${Consul.Port}"

  token   = "${Consul.Token}"

  #
  # Consul Service Discovery
  #

  auto_advertise = true
  checks_use_advertise = true
  server_auto_join = true

  #
  # Consul Service Settings
  # 
  server_service_name = "${Consul.ServiceName.Server}"

  client_service_name = "${Consul.ServiceName.Client}"
}

advertise {
  # Defaults to the first private IP address.
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}" # non-default ports may be specified
}


server {
  enabled          = true
  bootstrap_expect = 3
}



autopilot {
  cleanup_dead_servers      = true
  last_contact_threshold    = "200ms"
  max_trailing_logs         = 250
  server_stabilization_time = "10s"
  enable_redundancy_zones   = false
  disable_upgrade_migration = false
  enable_custom_upgrades    = false
}

