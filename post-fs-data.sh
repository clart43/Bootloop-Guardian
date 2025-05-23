#!/system/bin/sh

LOG_DIR=/data/adb/modules/Bootloop_Detector_Guardian/logs
LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"
BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"

echo "$(date) - [post-fs-data.sh] Iniciado." >> "$BOOT_PROGRESS_LOG"

for MODULE_PATH in /data/adb/modules/*; do
    MODULE_ID=$(basename "$MODULE_PATH")

    if [ "$MODULE_ID" = "Boot_Loop_Guardian" ]; then
        continue
    fi

    if [ ! -f "$MODULE_PATH/disable" ]; then
        echo "$(date) - [post-fs-data.sh] Módulo habilitado detectado: $MODULE_ID" >> "$BOOT_PROGRESS_LOG"

        echo "$MODULE_ID" > "$LAST_MODULE_LOG"
    fi
done

echo "$(date) - [post-fs-data.sh] Finalizado. El último módulo registrado en $LAST_MODULE_LOG es el último que Magisk intentó cargar." >> "$BOOT_PROGRESS_LOG"
