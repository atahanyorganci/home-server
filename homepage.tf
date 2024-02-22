resource "docker_image" "homepage" {
  name = "ghcr.io/gethomepage/homepage:latest"
}

resource "docker_volume" "homepage_config" {
  name   = "homepage_config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/homepage/config"
  }
}

resource "docker_volume" "homepage_assets" {
  name   = "homepage_data"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/homepage/public/assets"
  }
}

resource "docker_container" "homepage" {
  name  = "homepage"
  image = docker_image.homepage.image_id
  ports {
    internal = 3000
    external = 3000
  }
  volumes {
    volume_name    = docker_volume.homepage_config.name
    container_path = "/app/config"
  }
  volumes {
    volume_name    = docker_volume.homepage_assets.name
    container_path = "/app/public/assets"
  }
  networks_advanced {
    name = docker_network.media.name
  }
  networks_advanced {
    name = docker_network.download.name
  }
  env = ["PUID=${var.PUID}", "PGID=${var.PGID}"]
}
