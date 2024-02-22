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

resource "local_file" "homepage_config_files" {
  for_each = fileset("./homepage/config", "*")
  filename = "${var.DATA_HOME}/homepage/config/${each.key}"
  source   = "./homepage/config/${each.key}"
}

resource "local_file" "homepage_assets" {
  for_each = fileset("./homepage/assets", "*")
  filename = "${var.DATA_HOME}/homepage/public/assets/${each.key}"
  source   = "./homepage/assets/${each.key}"
}

locals {
  homepage_env_map = {
    JELLYFIN_PUBLIC_URL       = "https://${cloudflare_record.jellyfin.hostname}"
    JELLYFIN_INTERNAL_URL     = local.media_server_interal_url
    JELLYFIN_API_KEY          = var.JELLYIN_API_KEY
    PROWLARR_PUBLIC_URL       = "https://${cloudflare_record.prowlarr.hostname}"
    PROWLARR_INTERNAL_URL     = local.prowlarr_internal_url
    PROWLARR_API_KEY          = var.PROWLARR_API_KEY
    RADARR_PUBLIC_URL         = "https://${cloudflare_record.radarr.hostname}"
    RADARR_INTERNAL_URL       = local.radarr_internal_url
    RADARR_API_KEY            = var.RADARR_API_KEY
    SONARR_PUBLIC_URL         = "https://${cloudflare_record.sonarr.hostname}"
    SONARR_INTERNAL_URL       = local.sonarr_internal_url
    SONARR_API_KEY            = var.SONARR_API_KEY
    TRANSMISSION_PUBLIC_URL   = "https://${cloudflare_record.transmission.hostname}"
    TRANSMISSION_INTERNAL_URL = local.transmission_internal_url
  }
  homepage_env = [for k, v in local.homepage_env_map : "HOMEPAGE_VAR_${k}=${v}"]
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
  env = concat(local.homepage_env, ["PUID=${var.PUID}", "PGID=${var.PGID}"])
}
