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
  ports {
    internal = 8083
    external = 8083
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
  ports {
    internal = 80
    external = 13378
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
