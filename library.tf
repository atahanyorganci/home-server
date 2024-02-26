resource "docker_network" "library" {
  name   = "library"
  driver = "bridge"
}

resource "docker_image" "calibre_web" {
  name = "lscr.io/linuxserver/calibre-web:latest"
}

resource "docker_volume" "calibre_web_data" {
  name   = "calibre-web-data"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/calibre-web"
  }
}

resource "docker_container" "calibre_web" {
  name  = "calibre-web"
  image = docker_image.calibre_web.image_id
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  networks_advanced {
    name = docker_network.library.name
  }
  volumes {
    volume_name    = docker_volume.calibre_web_data.name
    container_path = "/config"
  }
  volumes {
    volume_name    = docker_volume.book_home.name
    container_path = "/books"
  }
}

resource "docker_image" "audiobookshelf" {
  name = "ghcr.io/advplyr/audiobookshelf:latest"
}

resource "docker_volume" "audiobookshelf_config" {
  name   = "audiobookshelf-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/audiobookshelf/config"
  }
}

resource "docker_volume" "audiobookshelf_metadata" {
  name   = "audiobookshelf-media"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/audiobookshelf/metadata"
  }
}

resource "docker_container" "audiobookshelf" {
  name  = "audiobookshelf"
  image = docker_image.audiobookshelf.image_id
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  networks_advanced {
    name = docker_network.library.name
  }
  volumes {
    volume_name    = docker_volume.audiobookshelf_config.name
    container_path = "/config"
  }
  volumes {
    volume_name    = docker_volume.audiobookshelf_metadata.name
    container_path = "/metadata"
  }
  volumes {
    volume_name    = docker_volume.audiobook_home.name
    container_path = "/audiobooks"
  }
}

locals {
  calibre_web_internal_url    = "http://${docker_container.calibre_web.name}:8083"
  audiobookshelf_internal_url = "http://${docker_container.audiobookshelf.name}:80"
}

resource "random_password" "library_tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "library_tunnel" {
  name       = "LibraryServer"
  account_id = var.CF_ACCOUNT_ID
  secret     = base64sha256(random_password.library_tunnel_secret.result)
}

resource "cloudflare_record" "calibre_web" {
  zone_id = var.CF_ZONE_ID
  name    = "library"
  value   = cloudflare_tunnel.library_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "audiobookshelf" {
  zone_id = var.CF_ZONE_ID
  name    = "audiobooks"
  value   = cloudflare_tunnel.library_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "library_tunnel" {
  tunnel_id  = cloudflare_tunnel.library_tunnel.id
  account_id = var.CF_ACCOUNT_ID
  config {
    ingress_rule {
      hostname = cloudflare_record.calibre_web.hostname
      service  = local.calibre_web_internal_url
    }
    ingress_rule {
      hostname = cloudflare_record.audiobookshelf.hostname
      service  = local.audiobookshelf_internal_url
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "docker_container" "library_tunnel" {
  image = docker_image.cloudflared.image_id
  name  = "library-tunnel"
  command = [
    "tunnel",
    "--no-autoupdate",
    "run",
    "--token",
    cloudflare_tunnel.library_tunnel.tunnel_token,
    cloudflare_tunnel.library_tunnel.id
  ]
  networks_advanced {
    name = docker_network.library.name
  }
}
