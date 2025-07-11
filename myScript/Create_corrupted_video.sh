# Crea un video di prova
ffmpeg -f lavfi -i testsrc=duration=15:size=640x360:rate=30 -c:v libx264 test.mp4

# Estrai solo i primi 50% dei byte del file per simulare un file troncato
filesize=$(stat -c%s "test.mp4")
half_size=$(( filesize / 2 ))
dd if=test.mp4 of=test_corrotto.mp4 bs=1 count=$half_size
