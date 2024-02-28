resource "docker_network" "dashboard" {
  name   = "dashboard"
  driver = "bridge"
}

resource "docker_image" "homepage" {
  name = "ghcr.io/gethomepage/homepage:latest"
}

resource "docker_volume" "homepage_config" {
  name   = "homepage-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/homepage/config"
  }
}

resource "docker_volume" "homepage_assets" {
  name   = "homepage-assets"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/homepage/public/assets"
  }
}

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "tunnel_readonly" {
  name = "TunnelReadonly"
  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.account["Argo Tunnel Read"]
    ]
    resources = {
      "com.cloudflare.api.account.${var.CF_ACCOUNT_ID}" = "*"
    }
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
    MEDIA_TUNNEL_ID           = cloudflare_tunnel.media_tunnel.id
    DOWNLOAD_TUNNEL_ID        = cloudflare_tunnel.download_tunnel.id
    CF_ACCOUNT_ID             = var.CF_ACCOUNT_ID
    CF_API_KEY                = cloudflare_api_token.tunnel_readonly.value
  }
  homepage_env = [for k, v in local.homepage_env_map : "HOMEPAGE_VAR_${k}=${v}"]
}

resource "docker_container" "homepage" {
  name  = "homepage"
  image = docker_image.homepage.image_id
  volumes {
    volume_name    = docker_volume.homepage_config.name
    container_path = "/app/config"
  }
  volumes {
    volume_name    = docker_volume.homepage_assets.name
    container_path = "/app/public/assets"
  }
  networks_advanced {
    name = docker_network.dashboard.name
  }
  networks_advanced {
    name = docker_network.media.name
  }
  networks_advanced {
    name = docker_network.download.name
  }
  env = concat(local.homepage_env, ["PUID=${var.PUID}", "PGID=${var.PGID}"])
  depends_on = [
    local_file.homepage_assets,
    local_file.homepage_config_files,
  ]
}

locals {
  homepage_internal_url = "http://${docker_container.homepage.name}:3000"
}

resource "random_password" "dashboard_tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "dashboard_tunnel" {
  name       = "DashboardServer"
  account_id = var.CF_ACCOUNT_ID
  secret     = base64sha256(random_password.dashboard_tunnel_secret.result)
}

resource "cloudflare_record" "homepage" {
  zone_id = var.CF_ZONE_ID
  name    = "dash"
  value   = cloudflare_tunnel.dashboard_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "dashboard_tunnel" {
  tunnel_id  = cloudflare_tunnel.dashboard_tunnel.id
  account_id = var.CF_ACCOUNT_ID
  config {
    ingress_rule {
      hostname = cloudflare_record.homepage.hostname
      service  = local.homepage_internal_url
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "docker_container" "dashboard_tunnel" {
  image = docker_image.cloudflared.image_id
  name  = "dashboard-tunnel"
  command = [
    "tunnel",
    "--no-autoupdate",
    "run",
    "--token",
    cloudflare_tunnel.dashboard_tunnel.tunnel_token,
    cloudflare_tunnel.dashboard_tunnel.id
  ]
  networks_advanced {
    name = docker_network.dashboard.name
  }
  depends_on = [docker_container.homepage]
}
