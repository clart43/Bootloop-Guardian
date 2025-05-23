#!/system/bin/sh

LOG_DIR=/data/adb/modules/Bootloop_Detector_Guardian/logs
mkdir -p "$LOG_DIR" || exit 1

LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"

BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"


echo "$(date) - Módulo 'Bootloop Detector Guardian' instalado/actualizado." > "$BOOT_PROGRESS_LOG"
echo "Modulo 'BootLoop Guardian' instalado." > "$LAST_MODULE_LOG"

ui_print "- Module 'BootLoopGuardian🛡️' instaled correctly"
ui_print "- This module will register the active modules before a This module will register the active modules before a bootloop."
ui_print "- To search the problematic module go tho this dir:"
ui_print "- /data/adb/modules/Bootloop_Detector_Guardian/logs/last_active_module.log"
