#!/usr/bin/env bash
set -eu

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

install_dependencies
install_docker
