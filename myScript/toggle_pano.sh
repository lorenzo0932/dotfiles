#!/bin/bash

EXTENSION_ID="pano@elhan.io"

# Controlla se l'estensione è abilitata
if gnome-extensions info $EXTENSION_ID | grep -q "Stato: ACTIVE"; then
  # Se è abilitata, la disabilita
  gnome-extensions disable $EXTENSION_ID
  notify-send "Estensione Pano" "L'estensione è stata disabilitata"
else
  # Altrimenti la abilita
  gnome-extensions enable $EXTENSION_ID
  notify-send "Estensione Pano" "L'estensione è stata abilitata"
fi

