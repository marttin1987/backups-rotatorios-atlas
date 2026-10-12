#!/bin/bash
# ===========================================================================
# Nombre: verificar.sh
# Proyecto: Auditar la integridad de las copias de seguridad mediante SHA-256
# Autor: Martin Coria
# Uso: ./src/verificar.sh
# Codigo de Salida: 0 (OK), 1 (INCONSISTENCIA) , 2 (ERROR CRITICO)
# ===========================================================================
set -euo pipefail

# 1. Determinar ruta dinamica del proyecto y cargar configuracion
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
	echo "ERROR: Archivo de configuracion '$CONFIG_FILE' no encontrado." >&2
	exit 2
fi

# Cargar variables del archivo .conf
#Shellcheck source/dev/null
source "$CONFIG_FILE"

# 2.  Validar que la ruta de destino exista
if [ ! -d "$DIR_DESTINO" ]; then
	echo "ERROR: El directorio de respaldos '$DIR_DESTINO' no existe." >&2
	exit 2
fi

echo "=============================================="
echo "   AUDITORIA DE INTEGRIDAD SHA-256 - ATLAS"
echo "=============================================="

ESTADO=0

cd "$DIR_DESTINO"

# 3. Iterar y auditar cada firma SHA-256 existente
SHAS_ENCONTRADOS=0
for HASH_FILE in backup_atlas_*.sha256; do
	[ -e "$HASH_FILE" ] || continue
	SHAS_ECONTRADOS=1
	echo -n "Verificando '$HASH_FILE':"
	if sha256sum -c "$HASH_FILE" --status 2>/dev/null ; then
		echo "OK"
	else
		echo "CORRUPTO O MODIFICADO"
		ESTADO=1
	fi
done

if [ "$SHAS_ENCONTRADOS" -eq 0 ]; then
	echo " No se encontraron archivos .sha256 para verificar en '$DIR_DESTINO'."
fi
echo "==========================================================="
exit "$ESTADO"
