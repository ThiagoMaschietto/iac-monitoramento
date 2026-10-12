resource "docker_network" "monitoring_net" {
  name = "monitoring_net"
}

resource "docker_image" "node_exporter" {
  name         = "prom/node-exporter:latest"
  keep_locally = true
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_container" "node_exporter" {
  image    = docker_image.node_exporter.image_id
  name     = "node_exporter"
  restart  = "unless-stopped"
  ports {
    internal = 9100
    external = 9100
  }
  networks_advanced {
    name = docker_network.monitoring_net.name
  }
}

resource "docker_container" "prometheus" {
  image    = docker_image.prometheus.image_id
  name     = "prometheus"
  restart  = "unless-stopped"
  ports {
    internal = 9090
    external = 9090
  }
  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = "${abspath(path.cwd)}/prometheus.yml"
    read_only      = true
  }
  networks_advanced {
    name = docker_network.monitoring_net.name
  }
  depends_on = [docker_container.node_exporter]
}

resource "docker_container" "grafana" {
  image    = docker_image.grafana.image_id
  name     = "grafana"
  restart  = "unless-stopped"
  ports {
    internal = 3000
    external = 3000
  }
  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]
  networks_advanced {
    name = docker_network.monitoring_net.name
  }
  depends_on = [docker_container.prometheus]
}