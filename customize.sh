#!/system/bin/sh

# --- LECTURA DINÁMICA DE PROPIEDADES ---
# Leer propiedades directamente de module.prop para asegurar consistencia.
# MODPATH es una variable global en el entorno de instalación de Magisk que apunta a la ruta de instalación.
MODULE_PROP="$MODPATH/module.prop"

# Extraer el ID, Nombre y Autor del módulo. grep y cut son herramientas estándar.
MOD_ID=$(grep_prop id "$MODULE_PROP")
MOD_NAME=$(grep_prop name "$MODULE_PROP")
MOD_AUTHOR=$(grep_prop author "$MODULE_PROP")

# Si no se puede obtener el nombre, usar el ID como fallback.
[ -z "$MOD_NAME" ] && MOD_NAME=$MOD_ID

# --- CONFIGURACIÓN DE RUTAS Y ARCHIVOS ---
LOG_DIR="/data/adb/modules/$MOD_ID/logs"

# Asegurar que el directorio de logs exista, saliendo si falla.
mkdir -p "$LOG_DIR" || exit 1

# Definir rutas completas a los archivos de log.
LAST_MODULE_LOG="$LOG_DIR/last_active_module.log"
BOOT_PROGRESS_LOG="$LOG_DIR/boot_progress.log"

# --- INICIALIZACIÓN DE LOGS ---
# Crear logs iniciales con información consistente.
echo "$(date) - Módulo '$MOD_NAME' instalado/actualizado." > "$BOOT_PROGRESS_LOG"
echo "Estado inicial: Módulo '$MOD_NAME' instalado correctamente." > "$LAST_MODULE_LOG"


# --- MENSAJES AL USUARIO (ui_print) ---
# Usar las variables para mostrar información precisa y consistente.

ui_print " "
ui_print "**********************************************"
ui_print " Módulo: $MOD_NAME"
ui_print " Autor: $MOD_AUTHOR"
ui_print "**********************************************"
ui_print " "
ui_print "- ¡Instalación completada! $MOD_NAME está activo."
ui_print " "
ui_print "- Este módulo monitoreará los arranques para detectar"
ui_print "  y recuperarse de posibles 'bootloops' causados por"
ui_print "  otros módulos de Magisk."
ui_print " "
ui_print "- Si se detecta un bootloop, los módulos se"
ui_print "  deshabilitarán y el causante (si se identifica)"
ui_print "  se mostrará en la descripción de este módulo."
ui_print " "
ui_print "- Los logs de diagnóstico se guardarán en:"
ui_print "  $LOG_DIR"
ui_print " "

# NOTA: La función 'grep_prop' es parte del entorno de instalación de Magisk y está disponible
# para ser usada en install.sh, por lo que no necesita ser definida.