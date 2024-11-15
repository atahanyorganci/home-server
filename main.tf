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
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "docker" {
  host = var.DOCKER_HOST
}

provider "cloudflare" {
  email   = var.CF_EMAIL
  api_key = var.CF_API_TOKEN
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

resource "docker_volume" "book_home" {
  name   = "book-home"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.BOOK_HOME}"
  }
}

resource "docker_volume" "audiobook_home" {
  name   = "audiobook-home"
  driver = "local"
  driver_opts = {
    type   = "none"
    o      = "bind"
    device = "${var.AUDIOBOOK_HOME}"
  }
}
