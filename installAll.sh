#! /bin/bash
# Installa tutti i componenti dal repository (funziona anche da clone fresco)

set -e

cd "$(dirname "$0")/installationScripts"
chmod +x *.sh

./installScripts.sh
./installDeps.sh
./installServices.sh
./installMPV.sh
./installNautilusScripts.sh
./installOpencodeConfig.sh

echo "Installazione completata."
