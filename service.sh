#!/system/bin/sh

LOG_DIR=/data/adb/modules/Bootloop_Detector_Guardian/logs
LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"
BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"
CRASH_LOG="$LOG_DIR/crash_events.log" 

BOOTLOOP_COUNTER_FILE="$LOG_DIR/bootloop_counter.txt"

BOOTLOOP_THRESHOLD=2 

SELF_MODULE_PROP="/data/adb/modules/Bootloop_Detector_Guardian/module.prop"


log_crash_event() {
    EVENT_MESSAGE="$1"
    echo "$(date) - CRASH_EVENT: $EVENT_MESSAGE" >> "$CRASH_LOG"
}

get_module_name() {
    MODULE_ID="$1"
    MODULE_PROP_PATH="/data/adb/modules/$MODULE_ID/module.prop"
    if [ -f "$MODULE_PROP_PATH" ]; then

        grep "^name=" "$MODULE_PROP_PATH" | cut -d'=' -f2- | tr -d '\r' 
    else
        echo "[Nombre no encontrado]"
    fi
}


disable_all_magisk_modules() {
    echo "$(date) - [service.sh] Deshabilitando todos los módulos Magisk..." >> "$BOOT_PROGRESS_LOG"

    CAUSING_MODULE_ID=""
    if [ -f "$LAST_MODULE_LOG" ]; then
        CAUSING_MODULE_ID=$(cat "$LAST_MODULE_LOG" | head -n 1 | tr -d '\r')
    fi

    if [ -n "$CAUSING_MODULE_ID" ] && [ "$CAUSING_MODULE_ID" != "Modulo 'Bootloop Detector Guardian' instalado." ]; then
        CAUSING_MODULE_NAME=$(get_module_name "$CAUSING_MODULE_ID")
        NEW_DESCRIPTION_LINE="description=BOOTLOOP DETECTADO! CAUSANTE: ID=$CAUSING_MODULE_ID, Nombre='$CAUSING_MODULE_NAME'."
        
        echo "$(date) - [service.sh] Módulo causante identificado: ID=$CAUSING_MODULE_ID, Nombre='$CAUSING_MODULE_NAME'" >> "$BOOT_PROGRESS_LOG"
              
        awk -v new_desc="$NEW_DESCRIPTION_LINE" '
            BEGIN { found_desc = 0 }
            /^description=/ {
                print new_desc
                found_desc = 1
                next
            }
            { print }
            END {
                if (!found_desc) {
                    print new_desc
                }
            }
        ' "$SELF_MODULE_PROP" > "$SELF_MODULE_PROP.tmp" && mv "$SELF_MODULE_PROP.tmp" "$SELF_MODULE_PROP"
        
        if [ $? -eq 0 ]; then
            echo "$(date) - [service.sh] module.prop de nuestro módulo actualizado con el causante." >> "$BOOT_PROGRESS_LOG"
        else
            echo "$(date) - [service.sh] ERROR: No se pudo actualizar el module.prop." >> "$BOOT_PROGRESS_LOG"
        fi
    else
        echo "$(date) - [service.sh] No se pudo identificar un módulo causante específico." >> "$BOOT_PROGRESS_LOG"
               
        NEW_DESCRIPTION_LINE="description=BOOTLOOP DETECTADO! (Causante no identificado, revisar logs)."
        awk -v new_desc="$NEW_DESCRIPTION_LINE" '
            BEGIN { found_desc = 0 }
            /^description=/ {
                print new_desc
                found_desc = 1
                next
            }
            { print }
            END {
                if (!found_desc) {
                    print new_desc
                }
            }
        ' "$SELF_MODULE_PROP" > "$SELF_MODULE_PROP.tmp" && mv "$SELF_MODULE_PROP.tmp" "$SELF_MODULE_PROP"
    fi

    for MODULE_PATH in /data/adb/modules/*; do
        MODULE_ID=$(basename "$MODULE_PATH")
        if [ "$MODULE_ID" = "Boot_Loop_Guardian" ]; then
            continue 
        fi
        if [ ! -f "$MODULE_PATH/disable" ]; then
            touch "$MODULE_PATH/disable"
            echo "$(date) - [service.sh] Módulo deshabilitado: $MODULE_ID" >> "$BOOT_PROGRESS_LOG"
        fi
    done

    echo "0" > "$BOOTLOOP_COUNTER_FILE" 
    echo "$(date) - [service.sh] Todos los módulos deshabilitados. Reiniciando ahora..." >> "$BOOT_PROGRESS_LOG"
    /system/bin/reboot
    exit 0
}

if [ -f "$BOOTLOOP_COUNTER_FILE" ]; then
    BOOT_COUNT=$(cat "$BOOTLOOP_COUNTER_FILE")
else
    BOOT_COUNT=0
fi
BOOT_COUNT=$((BOOT_COUNT + 1))
echo "$BOOT_COUNT" > "$BOOTLOOP_COUNTER_FILE"

echo "$(date) - [service.sh] Iniciado. Intento de arranque #: $BOOT_COUNT" >> "$BOOT_PROGRESS_LOG"

if [ "$BOOT_COUNT" -gt "$BOOTLOOP_THRESHOLD" ]; then
    echo "$(date) - [service.sh] Umbral de bootloop ($BOOTLOOP_THRESHOLD) superado. Actuando..." >> "$BOOT_PROGRESS_LOG"
    log_crash_event "Bootloop detectado: Superado el umbral de arranques fallidos."
    disable_all_magisk_modules
fi

sleep 90

ZYGOTE_PID=$(pidof zygote64 || pidof zygote)
SYSTEM_SERVER_PID=$(pidof system_server)
SYSTEM_UI_PID=$(pidof com.android.systemui)

if [ -n "$ZYGOTE_PID" ] && [ -n "$SYSTEM_SERVER_PID" ] && [ -n "$SYSTEM_UI_PID" ]; then

    echo "$(date) - [service.sh] Arranque exitoso detectado. Procesos clave activos." >> "$BOOT_PROGRESS_LOG"
    echo "0" > "$BOOTLOOP_COUNTER_FILE" 
    echo "" > "$LAST_MODULE_LOG"

    DEFAULT_DESCRIPTION="description=Detect and solve a bootloop and verify module that caused a bootloop, in case you installed many modules at the same time."
    awk -v default_desc="$DEFAULT_DESCRIPTION" '
        BEGIN { found_desc = 0 }
        /^description=/ {
            print default_desc
            found_desc = 1
            next
        }
        { print }
        END {
            if (!found_desc) {
                print default_desc
            }
        }
    ' "$SELF_MODULE_PROP" > "$SELF_MODULE_PROP.tmp" && mv "$SELF_MODULE_PROP.tmp" "$SELF_MODULE_PROP"
    echo "$(date) - [service.sh] Descripcion del modulo restaurada a la normalidad." >> "$BOOT_PROGRESS_LOG"

else
    
    echo "$(date) - [service.sh] Falla en el arranque: Procesos clave NO activos." >> "$BOOT_PROGRESS_LOG"
    if [ -z "$ZYGOTE_PID" ]; then echo "$(date) - [service.sh] Zygote no detectado." >> "$BOOT_PROGRESS_LOG"; fi
    if [ -z "$SYSTEM_SERVER_PID" ]; then echo "$(date) - [service.sh] System Server no detectado." >> "$BOOT_PROGRESS_LOG"; fi
    if [ -z "$SYSTEM_UI_PID" ]; then echo "$(date) - [service.sh] SystemUI no detectado." >> "$BOOT_PROGRESS_LOG"; fi

    log_crash_event "Arranque fallido: Procesos clave no detectados."
    disable_all_magisk_modules 
fi



touch "$CRASH_LOG"

while true; do
    logcat -d -s AndroidRuntime:E | grep "FATAL EXCEPTION" >> /dev/null
    if [ $? -eq 0 ]; then
        log_crash_event "FATAL EXCEPTION detectada en AndroidRuntime. Ver logcat completo."
    fi

    logcat -d -s SystemServer:E | grep "System has crashed" >> /dev/null
    if [ $? -eq 0 ]; then
        log_crash_event "SystemServer crash detectado. Ver logcat completo."
    fi

    sleep 300
done

echo "$(date) - [service.sh] El bucle de monitoreo ha terminado (no debería)." >> "$BOOT_PROGRESS_LOG"
