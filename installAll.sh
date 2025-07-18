#! /bin/bash

cd installationScripts
chmod +x *
./installServices.sh
cd $HOME/.local/share/myScript
./installMPV.sh
./installNautilusScripts.sh