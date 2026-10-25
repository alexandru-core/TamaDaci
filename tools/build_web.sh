#!/bin/bash
# Regenera el firmware combinado para el instalador web.
# Uso: bash tools/build_web.sh [--firmware-only]
set -e
cd "$(dirname "$0")/.."
FQBN="esp32:esp32:esp32s3:CDCOnBoot=cdc,FlashSize=16M,PSRAM=opi,PartitionScheme=app3M_fat9M_16MB"

SKETCHES=( *.ino )
if [ "${#SKETCHES[@]}" -ne 1 ] || [ ! -f "${SKETCHES[0]}" ]; then
  echo "Se esperaba exactamente un sketch .ino en la raiz" >&2
  exit 1
fi
SKETCH="${SKETCHES[0]}"

echo "Compilando ${SKETCH}..."
arduino-cli compile --fqbn "$FQBN" --export-binaries .

B=build/esp32.esp32.esp32s3
echo "Fusionando binarios..."
esptool.py --chip esp32s3 merge_bin -o web/firmware/tamapoke.bin \
  0x0     "$B/$SKETCH.bootloader.bin" \
  0x8000  "$B/$SKETCH.partitions.bin" \
  0xe000  "$B/boot_app0.bin" \
  0x10000 "$B/$SKETCH.bin"

echo "OK -> web/firmware/tamapoke.bin ($(du -h web/firmware/tamapoke.bin | cut -f1))"

if [ "${1:-}" != "--firmware-only" ]; then
  echo "Empaquetando sprites..."
  python3 tools/pack_bundle.py
fi
