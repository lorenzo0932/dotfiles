#!/usr/bin/env python3
"""Helper per drevo_keyboard_sync.py: applica un colore alla Drevo ed esce.

Il daemon lo lancia come subprocess con timeout: se il device e' incastrato
(un transfer libusb puo' bloccare per sempre), il figlio viene ucciso e il
thread del daemon non resta mai bloccato. Exit 0 = ok, altro = errore (il
messaggio va su stderr).
"""
import sys

from dtv2 import dtv2


def main():
    if len(sys.argv) != 5:
        sys.stderr.write("uso: kbd_apply_one.py R G B BRI_PCT\n")
        return 1
    try:
        r, g, b, bri = (int(x) for x in sys.argv[1:])
    except ValueError:
        sys.stderr.write("argomenti non validi\n")
        return 1
    try:
        dtv2().static((r, g, b), brightness=bri)
    except Exception as e:
        sys.stderr.write(f"{e}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
