#!/system/bin/sh

# Obtener el ID de este módulo dinámicamente para evitar errores.
SELF_MODULE_ID=$(basename "$(dirname "$0")")

# Definir rutas basadas en el ID del módulo.
LOG_DIR="/data/adb/modules/$SELF_MODULE_ID/logs"
LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"
BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"

# Es crucial asegurarse de que el directorio de logs exista antes de usarlo.
mkdir -p "$LOG_DIR"

# Función de log para consistencia.
log_message() {
    echo "$(date) - [post-fs-data.sh] - $1" >> "$BOOT_PROGRESS_LOG"
}

log_message "Iniciado. Buscando módulos habilitados..."

# Limpiar el log de la sesión anterior para empezar de cero.
# Si el script se interrumpe, el último valor que quede será el sospechoso.
>"$LAST_MODULE_LOG"

# Iterar sobre todos los directorios de módulos.
# Usar comillas en el globbing es más seguro.
for module_path in "/data/adb/modules"/*; do
    # Continuar si la entrada no es un directorio.
    [ ! -d "$module_path" ] && continue
    
    local module_id
    module_id=$(basename "$module_path")

    # Comparar con el ID dinámico para saltarse a sí mismo.
    if [ "$module_id" = "$SELF_MODULE_ID" ]; then
        continue
    fi

    # Comprobar si el módulo está habilitado (es decir, no tiene un archivo 'disable').
    if [ ! -f "$module_path/disable" ]; then
        log_message "Módulo habilitado detectado: $module_id"

        # Sobrescribir el archivo de log con el ID del último módulo habilitado encontrado.
        # Esto es intencional. Al final del bucle, este archivo solo contendrá
        # el ID del último módulo de la lista que estaba habilitado.
        echo "$module_id" > "$LAST_MODULE_LOG"
    fi
done

log_message "Análisis finalizado. El presunto causante de un posible bootloop se ha registrado."