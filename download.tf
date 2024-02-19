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

resource "docker_image" "transmission" {
  name = "lscr.io/linuxserver/transmission:latest"
}

resource "docker_volume" "transmission_config" {
  name   = "transmission-config"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.DATA_HOME}/transmission"
  }
}

resource "docker_container" "transmission" {
  image = docker_image.transmission.image_id
  name  = "transmission-tf"
  env = [
    "TZ=${var.TZ}",
    "PUID=${var.PUID}",
    "PGID=${var.PGID}",
  ]
  ports {
    internal = 9091
    external = 9091
  }
  ports {
    internal = 51413
    external = 51413
  }
  ports {
    internal = 51413
    external = 51413
    protocol = "udp"
  }
  networks_advanced {
    name = docker_network.download.name
  }
  volumes {
    volume_name    = docker_volume.transmission_config.name
    container_path = "/config"
  }
  volumes {
    volume_name    = docker_volume.download.name
    container_path = "/downloads"
  }
}

resource "random_password" "download_tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "download_tunnel" {
  name       = "Arr Stack"
  account_id = var.CF_ACCOUNT_ID
  secret     = base64sha256(random_password.download_tunnel_secret.result)
}

resource "cloudflare_record" "prowlarr" {
  zone_id = var.CF_ZONE_ID
  name    = "indexer"
  value   = cloudflare_tunnel.download_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "prowlarr" {
  zone_id          = var.CF_ZONE_ID
  name             = "Access application for ${cloudflare_record.prowlarr.hostname}"
  domain           = cloudflare_record.prowlarr.hostname
  session_duration = "1h"
}

resource "cloudflare_access_policy" "prowlarr" {
  application_id = cloudflare_access_application.prowlarr.id
  zone_id        = var.CF_ZONE_ID
  name           = "Policy for ${cloudflare_record.prowlarr.hostname}"
  precedence     = "1"
  decision       = "allow"
  include {
    email = [var.CF_EMAIL]
  }
}

resource "cloudflare_record" "radarr" {
  zone_id = var.CF_ZONE_ID
  name    = "movie"
  value   = cloudflare_tunnel.download_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "radarr" {
  zone_id          = var.CF_ZONE_ID
  name             = "Access application for ${cloudflare_record.radarr.hostname}"
  domain           = cloudflare_record.radarr.hostname
  session_duration = "1h"
}

resource "cloudflare_access_policy" "radarr" {
  application_id = cloudflare_access_application.radarr.id
  zone_id        = var.CF_ZONE_ID
  name           = "Policy for ${cloudflare_record.radarr.hostname}"
  precedence     = "1"
  decision       = "allow"
  include {
    email = [var.CF_EMAIL]
  }
}

resource "cloudflare_record" "sonarr" {
  zone_id = var.CF_ZONE_ID
  name    = "tv"
  value   = cloudflare_tunnel.download_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "sonarr" {
  zone_id          = var.CF_ZONE_ID
  name             = "Access application for ${cloudflare_record.sonarr.hostname}"
  domain           = cloudflare_record.sonarr.hostname
  session_duration = "1h"
}

resource "cloudflare_access_policy" "sonarr" {
  application_id = cloudflare_access_application.sonarr.id
  zone_id        = var.CF_ZONE_ID
  name           = "Policy for ${cloudflare_record.sonarr.hostname}"
  precedence     = "1"
  decision       = "allow"
  include {
    email = [var.CF_EMAIL]
  }
}

resource "cloudflare_record" "transmission" {
  zone_id = var.CF_ZONE_ID
  name    = "download"
  value   = cloudflare_tunnel.download_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "transmission" {
  zone_id          = var.CF_ZONE_ID
  name             = "Access application for ${cloudflare_record.transmission.hostname}"
  domain           = cloudflare_record.transmission.hostname
  session_duration = "1h"
}

resource "cloudflare_access_policy" "transmission" {
  application_id = cloudflare_access_application.transmission.id
  zone_id        = var.CF_ZONE_ID
  name           = "Policy for ${cloudflare_record.transmission.hostname}"
  precedence     = "1"
  decision       = "allow"
  include {
    email = [var.CF_EMAIL]
  }
}

resource "cloudflare_tunnel_config" "download_tunnel" {
  tunnel_id  = cloudflare_tunnel.download_tunnel.id
  account_id = var.CF_ACCOUNT_ID
  config {
    ingress_rule {
      hostname = cloudflare_record.prowlarr.hostname
      service  = "http://${docker_container.prowlarr.name}:9696"
    }
    ingress_rule {
      hostname = cloudflare_record.radarr.hostname
      service  = "http://${docker_container.radarr.name}:7878"
    }
    ingress_rule {
      hostname = cloudflare_record.sonarr.hostname
      service  = "http://${docker_container.sonarr.name}:8989"
    }
    ingress_rule {
      hostname = cloudflare_record.transmission.hostname
      service  = "http://${docker_container.transmission.name}:9091"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}


resource "docker_container" "download_tunnel" {
  image = docker_image.cloudflared.image_id
  name  = "download-tunnel"
  command = [
    "tunnel",
    "--no-autoupdate",
    "run",
    "--token",
    cloudflare_tunnel.download_tunnel.tunnel_token,
    cloudflare_tunnel.download_tunnel.id
  ]
  networks_advanced {
    name = docker_network.download.name
  }
}
