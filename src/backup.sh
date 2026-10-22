#!/bin/bash
# ==============================================================================
# Nombre: backup.sh
# Proyecto: ATLAS (backups-rotatorios-atlas)
# Proposito: Sistema automatizado de respaldos comprimidos, validacion por hash
# 	     SHA-256 y rotacion por antiguedad
# Autor: Martin Coria
# Uso: ./src/backup.sh
# Codigos de Salida: 0 (OK), 1 (ADVERTENCIA), 2 (ERROR CRITICO)
# ==============================================================================
set -euo pipefail
# 1. Determinar una ruta dinamica del script y cargar configuracion
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/config/backup.conf}"

if [ ! -f "$CONFIG_FILE" ]; then
	echo "ERROR: Archivo de configuracion '$CONFIG_FILE' no encontrado." >&2
	exit 2
fi

# Cargar variables del archivo .conf
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# 2. Validar tempranamente que las 5 variables existan antes de operar
if [ -z "${DIR_ORIGEN:-}" ] || [ -z "${DIR_DESTINO:-}" ] || [ -z "${LOG_FILE:-}" ] || [ -z "${DIAS_RETENCION:-}" ] || [ -z "${UMBRAL_DISCO_MAX:-}" ]; then	
	echo "ERROR: Variables de configuracion incompletas o no definidas en $CONFIG_FILE." >&2
	exit 2
fi

# Asegurar existencia de directorios de trabajo
mkdir -p "$DIR_DESTINO" "$(dirname "$LOG_FILE")"

FECHA=$(date "+%Y-%m-%d_%H-%M-%S")
ARCHIVADOR="backup_atlas_${FECHA}.tar.gz"
RUTA_TEMP="$DIR_DESTINO/backup_atlas_${FECHA}.tmp"
RUTA_BACKUP="$DIR_DESTINO/$ARCHIVADOR"

echo "====================================" | tee -a "$LOG_FILE"
echo " 	INICIANDO RESPALDO ATLAS - $(date "+%Y-%m-%d %H:%M:%S")" | tee -a "$LOG_FILE"
echo "====================================" | tee -a "$LOG_FILE"

# 3. Validar existencia del directorio origen
if [ ! -d "$DIR_ORIGEN" ]; then
	echo "ERROR CRITICO: El directorio origen '$DIR_ORIGEN' no existe." | tee -a "$LOG_FILE"
	exit 2
fi

# 4. Validar espacio en disco antes de compresion
PORCENTAJE_DISCO=$(df --output=pcent "$DIR_DESTINO" | tail -1 | tr -dc '0-9')
if [ "$PORCENTAJE_DISCO" -gt "$UMBRAL_DISCO_MAX" ]; then
	echo "ERROR CRITICO: Espacio en disco al ${PORCENTAJE_DISCO}%. Supera el umbral permitido (${UMBRAL_DISCO_MAX}%)." | tee -a "$LOG_FILE"
	exit 2
fi

# 5. Generar archivo comprimido de forma atomica
echo "[1] Comprimiendo '$DIR_ORIGEN' -> '$RUTA_BACKUP'..." | tee -a "$LOG_FILE"
if tar -czf "$RUTA_TEMP" -C "$(dirname "$DIR_ORIGEN")" "$(basename "$DIR_ORIGEN")" 2>/dev/null; then
	mv "$RUTA_TEMP" "$RUTA_BACKUP"
	echo "Comprension finalizada correctamente." | tee -a "$LOG_FILE"
else
	echo "ERROR CRITICO: Fallo la creacion del archivo de raspaldo" | tee -a "$LOG_FILE"
	rm -f "$RUTA_TEMP"
	exit 2
fi

# 6. Generar firma SHA-256 (Guardando nombre relativo para portabilidad y privacidad)
echo "[2] Generando firma SHA-256..." | tee -a "$LOG_FILE"
(
	cd "$DIR_DESTINO"
	sha256sum "$ARCHIVADOR" > "${ARCHIVADOR}.sha256"
)
HASH_GENERADO=$(awk '{print $1}' "${RUTA_BACKUP}.sha256")
echo "HASH: $HASH_GENERADO" | tee -a "$LOG_FILE"

# 7. Purga/Rotacion Especifica (Elimina tanto .tar.gz como su firma .tar.gz.sha256 asociada)
echo "[3] Aplicando politica de rotacion ($DIAS_RETENCION dias)..." | tee -a "$LOG_FILE"
ELIMINADOS=$(find "$DIR_DESTINO" -type f \( -name "backup_atlas_*.tar.gz" -o -name "backup_atlas_*.tar.gz.sha256" \) -mtime "+$DIAS_RETENCION" -print -delete | wc -l)

if [ "$ELIMINADOS" -gt 0 ]; then
	echo "Se purgaron $ELIMINADOS archivo(s) de respaldo antiguos de ATLAS." | tee -a "$LOG_FILE"
else
	echo "No se encontraron respaldos que superen los $DIAS_RETENCION dias." | tee -a "$LOG_FILE"
fi

echo "=================================================" | tee -a "$LOG_FILE"
echo "Respaldo completado con exito (Codigo: 0)." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

exit 0

