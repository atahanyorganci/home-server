resource "docker_network" "media" {
  name   = "media"
  driver = "bridge"
}

variable "media_server_name" {
  description = "The name of the media server."
  default     = "jellyfin-tf"
}

resource "docker_image" "jellyfin" {
  name = "lscr.io/linuxserver/jellyfin:latest"
}

resource "docker_volume" "jellyfin_config" {
  name   = "jellyfin-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/jellyfin"
  }
}

resource "docker_container" "jellyfin" {
  image = docker_image.jellyfin.image_id
  name  = var.media_server_name
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  networks_advanced {
    name = docker_network.media.name
  }
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
    volume_name    = docker_volume.jellyfin_config.name
    container_path = "/config"
  }
}

resource "docker_container" "media_tunnel" {
  image   = docker_image.cloudflared.image_id
  name    = "cloudflared-tf"
  command = ["tunnel", "--no-autoupdate", "run", "--token", cloudflare_tunnel.media_tunnel.tunnel_token, cloudflare_tunnel.media_tunnel.id]
  networks_advanced {
    name = docker_network.media.name
  }
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
      service  = "http://${var.media_server_name}:8096"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}
