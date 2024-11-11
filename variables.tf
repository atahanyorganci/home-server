variable "TZ" {
  description = "The time zone to use for the server."
  default     = "Etc/UTC"
}

variable "PUID" {
  description = "The user id to use for the server."
  default     = 1000
  type        = number
}

variable "PGID" {
  description = "The group id to use for the server."
  default     = 1000
  type        = number
}

variable "DOMAIN" {
  description = "Top level domain named shared by all applications"
  type        = string
}

variable "MOVIE_HOME" {
  description = "The path to the movie library."
  type        = string
}

variable "TV_HOME" {
  description = "The path to the TV library."
  type        = string
}

variable "DOWNLOAD_HOME" {
  description = "The path to the download directory."
  type        = string
}

variable "BOOK_HOME" {
  description = "The path to the book library."
  type        = string
}

variable "AUDIOBOOK_HOME" {
  description = "The path to the audiobook library."
  type        = string
}

variable "DATA_HOME" {
  description = "The path to the data directory where application state will be stored."
  type        = string
}

variable "CF_EMAIL" {
  description = "Cloudflare account email."
  type        = string
}

variable "CF_API_TOKEN" {
  description = "Cloudflare API token."
  type        = string
}

variable "CF_ACCOUNT_ID" {
  description = "Cloudflare account ID."
  type        = string
}

variable "CF_ZONE_ID" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "JELLYIN_API_KEY" {
  description = "The API key to use for the media server."
  type        = string
  sensitive   = true
}

variable "PROWLARR_API_KEY" {
  description = "The API key to use for Prowlarr."
  type        = string
  sensitive   = true
}


variable "RADARR_API_KEY" {
  description = "The API key to use for Radarr."
  type        = string
  sensitive   = true
}

variable "SONARR_API_KEY" {
  description = "The API key to use for Sonarr."
  type        = string
  sensitive   = true
}

variable "DOCKER_HOST" {
  description = "The host to use for the Docker provider."
  type        = string
  default     = "unix:///var/run/docker.sock"
}
