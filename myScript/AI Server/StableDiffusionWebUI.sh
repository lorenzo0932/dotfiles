#!/bin/bash

# Nome del container Docker
CONTAINER_NAME="rocm-docker"

# Percorso all'interno del container
CONTAINER_WORKDIR="/home/rocm-user/stable-diffusion-webui-forge"

# Nome dell'ambiente conda
CONDA_ENV_NAME="pytorch"

# Comando da eseguire all'interno del container
COMANDO_DA_ESEGUIRE="LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so HSA_OVERRIDE_GFX_VERSION=10.3.0 python launch.py  --listen --api --skip-load-model-at-start --enable-insecure-extension-access --cuda-stream"

# 1. Riavvia il container Docker
echo "Riavvio del container Docker '$CONTAINER_NAME'..."
docker restart "$CONTAINER_NAME"
echo "Container '$CONTAINER_NAME' riavviato."

# 2. Esegui il comando all'interno del container
echo "Esecuzione del comando all'interno del container '$CONTAINER_NAME'..."
docker exec -it "$CONTAINER_NAME" bash -c "
  # Cambia directory
  cd '$CONTAINER_WORKDIR'

  # Attiva l'ambiente conda
  source ~/.bashrc  # Assicurati che conda sia nel PATH
  conda activate '$CONDA_ENV_NAME'

  # Esegui il comando
  $COMANDO_DA_ESEGUIRE
"
echo "Comando eseguito all'interno del container."

echo "Script completato."