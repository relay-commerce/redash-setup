#!/usr/bin/env bash
set -eu

REDASH_BASE_PATH=/opt/redash

create_directory() {
    if [[ ! -e $REDASH_BASE_PATH ]]; then
        sudo mkdir -p $REDASH_BASE_PATH
        sudo chown $USER:$USER $REDASH_BASE_PATH
    fi
}

create_config() {
    read -p "Please enter the PostgreSQL server URL (postgres://...): " url
    export REDASH_DATABASE_URL=$url
    export COOKIE_SECRET=$(pwgen -1s 64)
    export SECRET_KEY=$(pwgen -1s 64)

    envsubst < .env.example > $REDASH_BASE_PATH/.env
}

setup_compose() {
    echo "Creating database..."
    docker-compose -f data/docker-compose.yml run --rm server create_db
    echo "Starting services..."
    docker-compose -f data/docker-compose.yml up -d
}

create_directory
create_config
setup_compose
