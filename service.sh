#!/system/bin/sh
# MOD=true

# --- INICIO DE CONFIGURACIÓN Y CONSTANTES ---

# Obtener el directorio del módulo dinámicamente
# $0 es la ruta del script, dirname nos da el directorio.
# Esto hace el script más portable si la estructura de carpetas cambia.
MODULE_PATH=$(dirname "$0")

# Definir el ID del módulo a partir de la ruta del script
# basename nos da el último componente de la ruta (el nombre de la carpeta del módulo)
SELF_MODULE_ID=$(basename "$MODULE_PATH")

LOG_DIR="/data/adb/modules/$SELF_MODULE_ID/logs"
LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"
BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"
CRASH_LOG="$LOG_DIR/crash_events.log"
BOOTLOOP_COUNTER_FILE="$LOG_DIR/bootloop_counter.txt"

SELF_MODULE_PROP="/data/adb/modules/$SELF_MODULE_ID/module.prop"

# Constantes
BOOTLOOP_THRESHOLD=2
DEFAULT_DESCRIPTION="description=Detect and solve a bootloop and verify module that caused a bootloop, in case you installed many modules at the same time."

# --- FIN DE CONFIGURACIÓN Y CONSTANTES ---


# --- INICIO DE FUNCIONES HELPER ---

# Función de logging centralizada para un formato consistente.
# Uso: log_message "Este es mi mensaje"
log_message() {
    echo "$(date) - [$SELF_MODULE_ID] - $1" >> "$BOOT_PROGRESS_LOG"
}

# Función para registrar eventos de crash específicos.
# Uso: log_crash_event "Se detectó un bootloop."
log_crash_event() {
    echo "$(date) - CRASH_EVENT: $1" >> "$CRASH_LOG"
}

# Función para obtener el nombre de un módulo de su module.prop
# Más eficiente y segura usando sed.
get_module_name() {
    local module_id="$1"
    local module_prop_path="/data/adb/modules/$module_id/module.prop"

    if [ -f "$module_prop_path" ]; then
        # Usamos sed para buscar la línea que empieza por "name=" y eliminar esa parte.
        # Es más eficiente que cat|grep|cut.
        # 's/^name=//; s/\r$//' -> s/original/reemplazo/; s/\r$// elimina el retorno de carro (CR)
        sed -n 's/^name=//p' "$module_prop_path" | tr -d '\r'
    else
        echo "[Nombre no encontrado]"
    fi
}

# Función para actualizar la descripción de nuestro propio módulo.
# Evita la duplicación de código.
update_self_description() {
    local new_description="description=$1"
    # Usamos sed para reemplazar la línea de descripción. Si no existe, la añade al final.
    # -i hace la edición "in-place", evitando crear un archivo temporal.
    # Primero comprobamos si la línea existe.
    if grep -q "^description=" "$SELF_MODULE_PROP"; then
        # La línea existe, la reemplazamos
        sed -i "s|^description=.*|$new_description|" "$SELF_MODULE_PROP"
    else
        # La línea no existe, la añadimos al final
        echo "$new_description" >> "$SELF_MODULE_PROP"
    fi

    if [ $? -eq 0 ]; then
        log_message "module.prop actualizado correctamente."
    else
        log_message "ERROR: No se pudo actualizar module.prop."
    fi
}

# Función principal para deshabilitar módulos en caso de bootloop.
disable_all_magisk_modules() {
    log_message "Deshabilitando todos los módulos Magisk excepto $SELF_MODULE_ID..."

    local causing_module_id=""
    if [ -f "$LAST_MODULE_LOG" ]; then
        # Leemos la primera línea del log del último módulo
        causing_module_id=$(head -n 1 "$LAST_MODULE_LOG" | tr -d '\r')
    fi

    if [ -n "$causing_module_id" ] && [ "$causing_module_id" != "Modulo '$SELF_MODULE_ID' instalado." ]; then
        local causing_module_name
        causing_module_name=$(get_module_name "$causing_module_id")
        log_message "Módulo causante identificado: ID=$causing_module_id, Nombre='$causing_module_name'"
        update_self_description "BOOTLOOP! Causa probable: '$causing_module_name' (ID: $causing_module_id)"
    else
        log_message "No se pudo identificar un módulo causante específico."
        update_self_description "BOOTLOOP DETECTADO! (Causa no identificada, revisar logs)."
    fi

    # Bucle para deshabilitar todos los módulos excepto el nuestro
    for module_path in /data/adb/modules/*; do
        local module_id
        module_id=$(basename "$module_path")
        
        # Comparamos con el ID obtenido dinámicamente
        if [ "$module_id" = "$SELF_MODULE_ID" ]; then
            log_message "Saltando deshabilitación de $SELF_MODULE_ID (este módulo)."
            continue
        fi

        # Si el archivo 'disable' no existe, lo creamos.
        if [ ! -f "$module_path/disable" ]; then
            touch "$module_path/disable"
            log_message "Módulo deshabilitado: $module_id"
        fi
    done

    # Reseteamos el contador y reiniciamos
    echo "0" > "$BOOTLOOP_COUNTER_FILE"
    log_message "Todos los módulos deshabilitados. Reiniciando ahora..."
    /system/bin/reboot
    exit 0
}


# --- INICIO DE LA LÓGICA PRINCIPAL DEL SCRIPT ---

# Asegurar que el directorio de logs exista
mkdir -p "$LOG_DIR"

# Incrementar y registrar el contador de arranque
if [ -f "$BOOTLOOP_COUNTER_FILE" ]; then
    boot_count=$(cat "$BOOTLOOP_COUNTER_FILE")
else
    boot_count=0
fi
boot_count=$((boot_count + 1))
echo "$boot_count" > "$BOOTLOOP_COUNTER_FILE"

log_message "Iniciado. Intento de arranque #: $boot_count"

# Comprobar si hemos superado el umbral de bootloop
if [ "$boot_count" -gt "$BOOTLOOP_THRESHOLD" ]; then
    log_message "Umbral de bootloop ($BOOTLOOP_THRESHOLD) superado. Tomando acción..."
    log_crash_event "Bootloop detectado: Superado el umbral de arranques fallidos."
    disable_all_magisk_modules
fi

# Esperar a que el sistema intente arrancar
# 90 segundos es un tiempo razonable.
sleep 90

# Verificar si los procesos clave del sistema están en ejecución
if pgrep -f "zygote" >/dev/null && pgrep -f "system_server" >/dev/null && pgrep -f "com.android.systemui" >/dev/null; then
    # ARRANQUE EXITOSO
    log_message "Arranque exitoso detectado. Procesos clave activos."
    echo "0" > "$BOOTLOOP_COUNTER_FILE"
    # Limpiamos el log del último módulo, ya que el arranque fue bueno.
    echo "" > "$LAST_MODULE_LOG"

    # Restaurar la descripción por defecto
    update_self_description "$DEFAULT_DESCRIPTION"
    log_message "Descripción del módulo restaurada a la normalidad."

else
    # ARRANQUE FALLIDO
    log_message "Falla en el arranque: Uno o más procesos clave NO están activos."
    # Opcional: Loguear qué proceso específico falta
    if ! pgrep -f "zygote" >/dev/null; then log_message "Proceso Zygote no encontrado."; fi
    if ! pgrep -f "system_server" >/dev/null; then log_message "Proceso System Server no encontrado."; fi
    if ! pgrep -f "com.android.systemui" >/dev/null; then log_message "Proceso SystemUI no encontrado."; fi
    
    log_crash_event "Arranque fallido: Procesos clave no detectados antes de la acción."
    disable_all_magisk_modules
fi

# --- BUCLE DE MONITOREO EN TIEMPO REAL (POST-ARRANQUE) ---

log_message "Iniciando monitoreo de logcat en tiempo real..."

# Monitorear logcat de forma eficiente para eventos de crash del sistema
# -b events: Buffer de eventos, más ligero.
# -s AndroidRuntime:E *:S -> Muestra solo logs de AndroidRuntime con prioridad Error o superior.
logcat -b crash -b main -s AndroidRuntime:E SystemServer:E *:S | while read -r line; do
    # 'case' es más eficiente que múltiples 'if/grep'
    case "$line" in
        *"FATAL EXCEPTION"*)
            log_crash_event "FATAL EXCEPTION detectada en AndroidRuntime. Forzando recuperación."
            disable_all_magisk_modules
            ;;
        *"System has crashed"*)
            log_crash_event "SystemServer crash detectado. Forzando recuperación."
            disable_all_magisk_modules
            ;;
    esac
done

# Esta línea solo se alcanzaría si el comando logcat falla por alguna razón.
log_message "El bucle de monitoreo ha terminado inesperadamente."