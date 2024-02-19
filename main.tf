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
    random = {
      source = "hashicorp/random"
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

resource "docker_image" "cloudflared" {
  name = "cloudflare/cloudflared:latest"
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

resource "docker_container" "media_tunnel" {
  image        = docker_image.cloudflared.image_id
  name         = "cloudflared-tf"
  network_mode = "host"
  command      = ["tunnel", "--no-autoupdate", "run", "--token", cloudflare_tunnel.media_tunnel.tunnel_token, cloudflare_tunnel.media_tunnel.id]
}

resource "random_password" "media_tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "media_tunnel" {
  name       = "Media Server"
  account_id = var.CF_ACCOUNT_ID
  secret     = base64sha256(random_password.media_tunnel_secret.result)
}

resource "cloudflare_record" "watch" {
  zone_id = var.CF_ZONE_ID
  name    = "watch"
  value   = cloudflare_tunnel.media_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "media_tunnel" {
  tunnel_id  = cloudflare_tunnel.media_tunnel.id
  account_id = var.CF_ACCOUNT_ID
  config {
    ingress_rule {
      hostname = cloudflare_record.watch.hostname
      service  = "http://localhost:8000"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}
