#!/bin/bash
START_TIME=$(date +%s)
IFS=$'\n'

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS
do
	echo -e "Sto verificando l'integrità di $i\n";
	nice -n 5 ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -v error -i $i -f null - 2>$(basename "$i").log; 
done
END_TIME=$(date +%s);
ELAPSED_TIME=$((END_TIME-START_TIME));
zenity --warning --text "Verifica file con GPU completata in $ELAPSED_TIME secondi!!"
