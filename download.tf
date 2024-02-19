resource "docker_network" "download" {
  name   = "download"
  driver = "bridge"
}

resource "docker_volume" "download" {
  name = "download"
}

resource "docker_image" "prowlarr" {
  name = "lscr.io/linuxserver/prowlarr:latest"
}

resource "docker_volume" "prowlarr_config" {
  name   = "prowlarr-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/prowlarr"
  }
}

resource "docker_container" "prowlarr" {
  image = docker_image.prowlarr.image_id
  name  = "prowlarr-tf"
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  ports {
    internal = 9696
    external = 9696
  }
  networks_advanced {
    name = docker_network.download.name
  }
  volumes {
    volume_name    = docker_volume.prowlarr_config.name
    container_path = "/config"
  }
}

resource "docker_image" "radarr" {
  name = "lscr.io/linuxserver/radarr:latest"
}

resource "docker_volume" "radarr_config" {
  name   = "radarr-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/radarr"
  }
}

resource "docker_container" "radarr" {
  image = docker_image.radarr.image_id
  name  = "radarr-tf"
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  ports {
    internal = 7878
    external = 7878
  }
  networks_advanced {
    name = docker_network.download.name
  }
  volumes {
    volume_name    = docker_volume.radarr_config.name
    container_path = "/config"
  }
  volumes {
    volume_name    = docker_volume.download.name
    container_path = "/downloads"
  }
  volumes {
    volume_name    = docker_volume.movie_home.name
    container_path = "/movies"
  }
}

resource "docker_image" "sonarr" {
  name = "lscr.io/linuxserver/sonarr:latest"
}

resource "docker_volume" "sonarr_config" {
  name   = "sonarr-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/sonarr"
  }
}

resource "docker_container" "sonarr" {
  image = docker_image.sonarr.image_id
  name  = "sonarr-tf"
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  ports {
    internal = 8989
    external = 8989
  }
  networks_advanced {
    name = docker_network.download.name
  }
  volumes {
    volume_name    = docker_volume.sonarr_config.name
    container_path = "/config"
  }
  volumes {
    volume_name    = docker_volume.download.name
    container_path = "/downloads"
  }
  volumes {
    volume_name    = docker_volume.tv_home.name
    container_path = "/tv"
  }
}


