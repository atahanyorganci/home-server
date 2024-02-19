terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "cloudflare" {
  email   = var.CF_EMAIL
  api_key = var.CF_API_TOKEN
}

resource "docker_image" "jellyfin" {
  name = "lscr.io/linuxserver/jellyfin:latest"
}

resource "docker_volume" "movie_home" {
  name   = "movie-home"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = var.MOVIE_HOME
  }
}

resource "docker_volume" "tv_home" {
  name   = "tv-home"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = var.TV_HOME
  }
}

resource "docker_container" "jellyfin" {
  image = docker_image.jellyfin.image_id
  name  = "jellyfin-tf"
  ports {
    internal = 8096
    external = 8000
  }
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  volumes {
    volume_name    = docker_volume.movie_home.name
    read_only      = true
    container_path = "/data/movies"
  }
  volumes {
    volume_name    = docker_volume.tv_home.name
    read_only      = true
    container_path = "/data/tvshows"
  }
  volumes {
    volume_name    = "jellyin-config"
    host_path      = "${var.DATA_HOME}/jellyfin"
    container_path = "/config"
  }
}
