#!/usr/bin/env bash
set -eu

REDASH_BASE_PATH=/opt/redash

install_dependencies() {
    sudo amazon-linux-extras install epel -y
    sudo yum install pwgen
}

install_docker() {
    # Install Docker
    sudo yum install docker

    # Install Docker Compose
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Allow current user to run Docker commands
    sudo usermod -aG docker $USER

    sudo systemctl enable docker
    sudo systemctl start docker
}

create_directories() {
    if [[ ! -e $REDASH_BASE_PATH ]]; then
        sudo mkdir -p $REDASH_BASE_PATH
        sudo chown $USER:$USER $REDASH_BASE_PATH
    fi

    if [[ ! -e $REDASH_BASE_PATH/nginx ]]; then
        mkdir -p $REDASH_BASE_PATH/nginx/certs
        mkdir -p $REDASH_BASE_PATH/nginx/certs-data
    fi
}

create_env_file() {
    read -p "REDASH_DATABASE_URL (postgres://...): " database_url
    read -p "REDASH_GOOGLE_CLIENT_ID: " google_client_id
    read -p "REDASH_GOOGLE_CLIENT_SECRET: " google_client_secret

    export REDASH_DATABASE_URL=$database_url
    export REDASH_GOOGLE_CLIENT_ID=$google_client_id
    export REDASH_GOOGLE_CLIENT_SECRET=$google_client_secret
    export COOKIE_SECRET=$(pwgen -1s 64)
    export SECRET_KEY=$(pwgen -1s 64)

    envsubst < .env.example > $REDASH_BASE_PATH/.env
}

setup_nginx() {
    read -p "Enter Redash hostname (e.g. redash.example.com): " hostname

   if [ -d "$REDASH_BASE_PATH/nginx/certs/live" ]; then
        template_file="data/nginx-https.conf"
    else
       template_file="data/nginx.conf"
    fi

    sed "s/redash.example.com/$hostname/g" "$template_file" > "$REDASH_BASE_PATH/nginx/nginx.conf"
}

start_app() {
    docker-compose -f data/docker-compose.yml run --rm server create_db
    docker-compose -f data/docker-compose.yml up -d
}
