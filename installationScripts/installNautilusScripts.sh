#! /bin/bash

mkdir -p "$HOME/.local/share/nautilus/scripts"
cp -r ../nautilus/scripts/. "$HOME/.local/share/nautilus/scripts/"
chmod -R +x "$HOME/.local/share/nautilus/scripts/"
