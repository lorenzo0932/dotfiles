#! /bin/bash

#Per installare i servizi è richiesto che vengano installati gli script:
./installScripts

#Copio i servizi nella location corretta 
USER_SERVICES_LOCATION=$HOME/.config/share/systemd
cp  ../systemd/* "$USER_SERVICES_LOCATION"

#Abilito i servizi non dipendenti da programmi esterni:
systemctl --user daemon-reload
systemctl --user enable --now downloadAnime.timer flatpak-update.timer rsync.timer

