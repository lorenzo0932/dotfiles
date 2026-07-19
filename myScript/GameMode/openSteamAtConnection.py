#!/usr/bin/python

import os
import sys
import subprocess
import logging
from pathlib import Path
import time

# ==============================================================================
# CONFIGURAZIONE FILTRI HARDWARE (WHITELIST)
# Lascia una stringa vuota "" per disabilitare un filtro specifico.
# I valori reali del tuo controller verranno stampati nel file di log ad ogni connessione.
# ==============================================================================
TARGET_VENDOR = "045e"   # Filtra per produttore (es: "045e" = Microsoft)
TARGET_PRODUCT = ""      # Filtra per modello specifico (lascia vuoto per qualsiasi controller Microsoft)
TARGET_UNIQ = ""         # Filtra per Seriale / MAC Address specifico (consigliato per evitare altri controller)
TARGET_PHYS = ""         # Filtra per una specifica porta fisica USB (es: "usb-0000:2b:00.3-1/input0")
# ==============================================================================

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
        self.connected_joysticks = {}  # Mappa: basename -> is_target (bool)
        self.monitor_path = "/dev/input"
        self.input_file = Gio.file_new_for_path(self.monitor_path)
        self.monitor = self.input_file.monitor_directory(Gio.FileMonitorFlags.NONE, None)
        self.monitor.connect("changed", self.on_input_changed)
        logging.info(f"Xbox Controller Monitor avviato, in ascolto su {self.monitor_path}")
        self.check_for_controller()

    def get_device_info(self, basename):
        """Estrae i dettagli hardware del dispositivo da sysfs"""
        info = {"name": "", "vendor": "", "product": "", "uniq": "", "phys": ""}
        base_path = f"/sys/class/input/{basename}/device"
        
        # Attendiamo un istante per dare tempo al kernel di popolare sysfs
        time.sleep(0.1)
        
        try:
            if os.path.exists(f"{base_path}/name"):
                with open(f"{base_path}/name", "r") as f:
                    info["name"] = f.read().strip()
            if os.path.exists(f"{base_path}/id/vendor"):
                with open(f"{base_path}/id/vendor", "r") as f:
                    info["vendor"] = f.read().strip().lower()
            if os.path.exists(f"{base_path}/id/product"):
                with open(f"{base_path}/id/product", "r") as f:
                    info["product"] = f.read().strip().lower()
            if os.path.exists(f"{base_path}/uniq"):
                with open(f"{base_path}/uniq", "r") as f:
                    info["uniq"] = f.read().strip().lower()
            if os.path.exists(f"{base_path}/phys"):
                with open(f"{base_path}/phys", "r") as f:
                    info["phys"] = f.read().strip().lower()
        except Exception as e:
            logging.error(f"Errore nella lettura dei dettagli hardware per {basename}: {e}")
            
        return info

    def matches_target(self, info):
        """Verifica se le informazioni del dispositivo corrispondono ai filtri impostati"""
        # Se è specificato il Vendor, deve corrispondere
        if TARGET_VENDOR and info["vendor"] != TARGET_VENDOR.lower().strip():
            return False
        # Se è specificato il Product, deve corrispondere
        if TARGET_PRODUCT and info["product"] != TARGET_PRODUCT.lower().strip():
            return False
        # Se è specificato l'ID univoco/seriale/MAC, deve corrispondere
        if TARGET_UNIQ and info["uniq"] != TARGET_UNIQ.lower().strip():
            return False
        # Se è specificata la porta fisica, deve corrispondere
        if TARGET_PHYS and info["phys"] != TARGET_PHYS.lower().strip():
            return False
            
        # Se nessun filtro stretto è impostato, eseguiamo un controllo generico sul nome per sicurezza
        if not (TARGET_VENDOR or TARGET_PRODUCT or TARGET_UNIQ or TARGET_PHYS):
            name_lower = info["name"].lower()
            if "xbox" not in name_lower and "x-box" not in name_lower:
                return False
                
        return True

    def on_input_changed(self, monitor, file1, file2, event_type):
        """Callback quando il filesystem input cambia"""
        basename = file1.get_basename()
        
        # Filtra solo i file che iniziano con "js" seguiti da un numero (es. js0, js1)
        if basename.startswith('js') and basename[2:].isdigit():
            if event_type == Gio.FileMonitorEvent.CREATED:
                info = self.get_device_info(basename)
                logging.info(
                    f"[CONNESSIONE] Rilevato dispositivo {basename}:\n"
                    f"  - Nome: {info['name']}\n"
                    f"  - Vendor ID: {info['vendor']}\n"
                    f"  - Product ID: {info['product']}\n"
                    f"  - Unique ID (Serial/MAC): {info['uniq']}\n"
                    f"  - Phys (Porta): {info['phys']}"
                )
                
                if self.matches_target(info):
                    self.connected_joysticks[basename] = True
                    logging.info(f"Dispositivo {basename} corrisponde ai criteri del controller target.")
                    self.on_controller_connected()
                else:
                    self.connected_joysticks[basename] = False
                    logging.info(f"Dispositivo {basename} ignorato (non corrisponde ai criteri).")
                    
            elif event_type == Gio.FileMonitorEvent.DELETED:
                was_target = self.connected_joysticks.pop(basename, False)
                if was_target:
                    logging.info(f"Controller target '{basename}' rimosso.")
                    # Se non ci sono altri controller target rimasti connessi, reimposta lo stato
                    if not any(self.connected_joysticks.values()):
                        self.on_controller_disconnected()

    def check_for_controller(self):
        """Verifica se il controller target è già connesso all'avvio"""
        joysticks = list(Path(self.monitor_path).glob("js*"))
        for j in joysticks:
            basename = j.name
            if basename[2:].isdigit():
                info = self.get_device_info(basename)
                if self.matches_target(info):
                    self.connected_joysticks[basename] = True
                    logging.info(f"Controller target '{basename}' già presente all'avvio.")
                    self.on_controller_connected()
                else:
                    self.connected_joysticks[basename] = False

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
        """Callback quando il controller target si connette"""
        if not self.controller_connected:
            self.controller_connected = True
            logging.info("Controller target connesso - Esecuzione azioni")
            self.close_applications()
            self.launch_steam_big_picture()

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
            logging.info("Controller target disconnesso - Reset stato")

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
