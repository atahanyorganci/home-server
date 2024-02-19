
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

variable "MOVIE_HOME" {
  description = "The path to the movie library."
  type        = string
}

variable "TV_HOME" {
  description = "The path to the TV library."
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
