# Home Server

Terraform definitions for running Docker images in local network and exposing them to the internet using Cloudflare tunnels with Cloudflare Zero trust.

## Configuration

Home server requires various variables to be set for finding media, download area, api keys etc. [`Justfile`](./Justfile) assumes that these variables are stored in [`env.tfvars`](./env.tfvars) file. Running `just secret` will download secrets from Doppler and create initial `env.tfvars` file. All variables required are below.

```env
DOMAIN      = "example.com"

// Media Storage
DATA_HOME      = "./data"
AUDIOBOOK_HOME = "~/Music/Audiobooks"
BOOK_HOME      = "~/Documents/Books"
DOWNLOAD_HOME  = "~/Downloads"
MOVIE_HOME     = "~/Videos/Movies"
TV_HOME        = "~/Videos/TV Shows"

// Service API Keys
JELLYIN_API_KEY  = "XXXXXXXXXXXXXXX"
PROWLARR_API_KEY = "XXXXXXXXXXXXXXX"
RADARR_API_KEY   = "XXXXXXXXXXXXXXX"
SONARR_API_KEY   = "XXXXXXXXXXXXXXX"

// Cloudflare
CF_ACCOUNT_ID = "XXXXXXXXXXXXXXX"
CF_API_TOKEN  = "XXXXXXXXXXXXXXX"
CF_EMAIL      = "XXXXXXXXXXXXXXX"
CF_ZONE_ID    = "XXXXXXXXXXXXXXX"

```
