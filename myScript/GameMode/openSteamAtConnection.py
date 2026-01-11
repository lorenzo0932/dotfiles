#!/usr/bin/python

import os
import sys
import subprocess
import logging
from pathlib import Path
import time

# Setup logging
log_dir = Path.home() / ".local" / "share"
log_dir.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=str(log_dir / "xbox-controller.log"),
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

try:
    import gi
    gi.require_version('Gio', '2.0')
    from gi.repository import Gio, GLib
except ImportError:
    logging.error("PyGObject non installato. Installa: sudo dnf install python3-gobject")
    sys.exit(1)

class XboxControllerMonitor:
    def __init__(self):
        self.controller_connected = False
        self.monitor_path = "/dev/input"
        self.input_file = Gio.file_new_for_path(self.monitor_path)
        self.monitor = self.input_file.monitor_directory(Gio.FileMonitorFlags.NONE, None)
        self.monitor.connect("changed", self.on_input_changed)
        logging.info(f"Xbox Controller Monitor avviato, in ascolto su {self.monitor_path}")
        self.check_for_controller()

    def on_input_changed(self, monitor, file1, file2, event_type):
        """Callback quando il filesystem input cambia"""
        if file1.get_basename() == 'js1':
            if event_type == Gio.FileMonitorEvent.CREATED:
                logging.info("Controller js1 rilevato.")
                self.on_controller_connected()
            elif event_type == Gio.FileMonitorEvent.DELETED:
                logging.info("Controller js1 disconnesso.")
                self.on_controller_disconnected()

    def check_for_controller(self):
        """Verifica se il controller è già connesso all'avvio"""
        if Path(self.monitor_path + "/js1").exists():
            logging.info("Controller js1 già presente all'avvio.")
            self.on_controller_connected()

    def launch_steam_big_picture(self):
        """Lancia Steam in Big Picture mode"""
        try:
            subprocess.Popen(["/usr/bin/steam", "%U"], 
                           stdout=subprocess.DEVNULL, 
                           stderr=subprocess.DEVNULL)
            logging.info("Steam Big Picture lanciato")
        except Exception as e:
            logging.error(f"Errore lancio Steam: {e}")

    def on_controller_connected(self):
        """Callback quando il controller si accende"""
        if not self.controller_connected:
            self.controller_connected = True
            logging.info("Controller Xbox acceso - Esecuzione azioni")
            self.close_applications()
            self.launch_steam_big_picture()
            # GLib.MainLoop().quit() # Opzionale: esce dopo aver avviato Steam

    def close_applications(self):
        """Chiude le applicazioni specificate prima di avviare Steam."""
        logging.info("Chiusura applicazioni in corso...")
        apps_to_kill = ["zen", "firefox-bin", "code", "Telegram", "jellyfin-desktop"]
        for app in apps_to_kill:
            try:
                subprocess.run(["/usr/bin/killall", "-s", "9", app], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                logging.info(f"Terminato: {app}")
            except Exception as e:
                logging.error(f"Errore durante la terminazione di {app}: {e}")

        try:
            subprocess.Popen(["flatpak", "run", "org.telegram.desktop", "-startintray"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            logging.info("Telegram avviato in background")
        except Exception as e:
            logging.error(f"Errore durante l'avvio di Telegram: {e}")
        
    def on_controller_disconnected(self):
        """Callback quando il controller si disconnette"""
        if self.controller_connected:
            self.controller_connected = False
            logging.info("Controller Xbox disconnesso - Reset stato")

    def run(self):
        """Avvia il monitor"""
        try:
            self.loop = GLib.MainLoop()
            logging.info("MainLoop avviato")
            self.loop.run()
        except KeyboardInterrupt:
            logging.info("Monitor arrestato dall'utente")
            sys.exit(0)
        except Exception as e:
            logging.error(f"Errore MainLoop: {e}")
            sys.exit(1)

if __name__ == "__main__":
    monitor = XboxControllerMonitor()
    monitor.run()
