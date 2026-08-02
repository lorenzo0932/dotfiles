#!/bin/bash

# Nome del container Docker
CONTAINER_NAME="rocm-terminal"

# Percorso all'interno del container
CONTAINER_WORKDIR="/home/rocm-user/SwarmUI"

# Nome dell'ambiente conda
CONDA_ENV_NAME="pytorch"

# Comando da eseguire all'interno del container
COMANDO_DA_ESEGUIRE="PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.6,max_split_size_mb:128 ./launch-linux.sh --launch_mode none --loglevel verbose"


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