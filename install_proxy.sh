#!/bin/bash

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Função para instalar o Docker
install_docker() {
    echo "Docker não encontrado, iniciando a instalação..."

    # Atualize o índice de pacotes e instale dependências
    sudo apt-get update && sudo apt-get install -y ca-certificates curl
    if [ $? -ne 0 ]; then
        echo "Erro ao atualizar pacotes ou instalar dependências."
        exit 1
    fi

    # Adicione a chave GPG oficial do Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    if [ $? -ne 0 ]; then
        echo "Erro ao adicionar a chave GPG do Docker."
        exit 1
    fi

    # Adicione o repositório do Docker às fontes do Apt
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    if [ $? -ne 0 ]; then
        echo "Erro ao adicionar o repositório do Docker."
        exit 1
    fi

    # Instale o Docker
    VERSION_STRING=$(apt-cache madison docker-ce | awk '{ print $3 }' | head -n 1)
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
    if [ $? -ne 0 ]; then
        echo "Erro ao instalar o Docker."
        exit 1
    fi

    echo "Docker foi instalado com sucesso."
}

# Verifique se o Docker já está instalado
if command_exists docker; then
    echo "Docker já está instalado."
else
    install_docker
fi

# Verifique se o Apache2 está instalado
if dpkg -l | grep -q apache2; then
    echo "Apache2 encontrado, removendo..."
    sudo apt-get remove -y apache2
    if [ $? -ne 0 ]; then
        echo "Erro ao remover o Apache2."
        exit 1
    fi
    echo "Apache2 foi removido com sucesso."
else
    echo "Apache2 não está instalado."
fi

# Navegue para a pasta /opt e crie o arquivo docker-compose.yml
cd /opt
sudo bash -c 'cat <<EOL > docker-compose.yml
version: "3.8"
services:
  app:
    image: "jc21/nginx-proxy-manager:latest"
    restart: unless-stopped
    ports:
      - "80:80" # Public HTTP Port
      - "443:443" # Public HTTPS Port
      - "81:81" # Admin Web Port
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOL'

# Execute o Docker Compose
sudo docker compose up -d

echo "NGINX Proxy Manager foi configurado e está em execução."
