set export

VARS_FILE := "env.tfvars"

setup:
    mkdir -p data/audiobookshelf/config
    mkdir -p data/audiobookshelf/metadata
    mkdir -p data/calibre-web
    mkdir -p data/homepage
    mkdir -p data/jellyfin
    mkdir -p data/prowlarr
    mkdir -p data/radarr
    mkdir -p data/sonarr
    mkdir -p data/transmission

init:
    terraform init

plan *args:
    terraform plan -var-file=$VARS_FILE {{args}}

apply *args:
    terraform apply -var-file=$VARS_FILE {{args}}

destory *args:
    terraform destroy -var-file=$VARS_FILE {{args}}

restart:
    docker restart $(docker ps -q)