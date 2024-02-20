output "media_server" {
  value = cloudflare_record.jellyfin.hostname
}

output "torrent_indexer" {
  value = cloudflare_record.prowlarr.hostname
}

output "movie_manager" {
  value = cloudflare_record.radarr.hostname
}

output "tv_manager" {
  value = cloudflare_record.sonarr.hostname
}

output "torrent_client" {
  value = cloudflare_record.transmission.hostname
}


