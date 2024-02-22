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
