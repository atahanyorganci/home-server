output "media" {
  value = {
    tunnel = {
      id    = cloudflare_tunnel.media_tunnel.id
      name  = cloudflare_tunnel.media_tunnel.name
      cname = cloudflare_tunnel.media_tunnel.cname
    }
    cname      = [cloudflare_record.jellyfin.hostname]
    containers = [docker_container.jellyfin.name, docker_container.media_tunnel.name]
  }
}

output "download" {
  value = {
    tunnel = {
      id    = cloudflare_tunnel.download_tunnel.id
      name  = cloudflare_tunnel.download_tunnel.name
      cname = cloudflare_tunnel.download_tunnel.cname
    }
    cname = [
      cloudflare_record.prowlarr.hostname,
      cloudflare_record.sonarr.hostname,
      cloudflare_record.radarr.hostname,
      cloudflare_record.transmission.hostname
    ]
    containers = [
      docker_container.prowlarr.name,
      docker_container.sonarr.name,
      docker_container.radarr.name,
      docker_container.transmission.name,
      docker_container.download_tunnel.name
    ]
  }
}

output "library" {
  value = {
    tunnel = {
      id    = cloudflare_tunnel.library_tunnel.id
      name  = cloudflare_tunnel.library_tunnel.name
      cname = cloudflare_tunnel.library_tunnel.cname
    }
    cname      = [cloudflare_record.calibre_web.hostname, cloudflare_record.audiobookshelf.hostname]
    containers = [docker_container.calibre_web.name, docker_container.audiobookshelf.name, docker_container.library_tunnel.name]
  }
}

output "dashboard" {
  value = {
    tunnel = {
      id    = cloudflare_tunnel.dashboard_tunnel.id
      name  = cloudflare_tunnel.dashboard_tunnel.name
      cname = cloudflare_tunnel.dashboard_tunnel.cname
    }
    cname      = [cloudflare_record.homepage.hostname]
    containers = [docker_container.homepage.name, docker_container.dashboard_tunnel.name]
  }
}
