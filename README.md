# 💾 Backups Rotatorios ATLAS

Sistema de copias de seguridad automatizadas para servidores Linux, escrito en Bash: comprime una carpeta, firma cada copia con SHA-256, borra las copias viejas y permite verificar en cualquier momento que nada se haya corrompido.

## 📋 Características

- **Compresión atómica:** la copia se crea primero como archivo `.tmp` y solo se renombra a `.tar.gz` si `tar` terminó bien. Nunca queda un backup a medias.
- **Firma de integridad portátil:** cada backup genera un `.sha256` con ruta relativa, para que se pueda verificar desde cualquier carpeta o equipo.
- **Auditoría:** `src/verificar.sh` comprueba todas las firmas y devuelve un código de salida.
- **Rotación segura:** borra solo los archivos `backup_atlas_*` con más de N días. Los demás archivos de la carpeta no se tocan.
- **Validaciones previas:** revisa que existan las variables de configuración y la carpeta de origen, y que el disco no supere el umbral.
- **Registro:** cada ejecución queda en un log con fecha y hora.

## 📁 Estructura

```text
backups-rotatorios-atlas/
├── config/
│   └── backup.conf      # Configuración (rutas, retención, umbral)
├── src/
│   ├── backup.sh        # Crea el backup, lo firma y rota los viejos
│   └── verificar.sh     # Audita las firmas SHA-256
├── backups/             # Se crea solo; guarda las copias (no se sube a Git)
└── logs/                # Se crea solo; guarda el log (no se sube a Git)
```

## 🛠️ Instalación

```bash
git clone git@github.com:marttin1987/backups-rotatorios-atlas.git
cd backups-rotatorios-atlas
chmod +x src/backup.sh src/verificar.sh
```

Requisitos: Bash y las herramientas estándar de Linux (`tar`, `sha256sum`, `find`, `df`). Probado en Debian y Ubuntu.

## ⚙️ Configuración

Editá `config/backup.conf`:

```bash
DIR_ORIGEN="$HOME/proyecto_atlas"                           # Carpeta a respaldar
DIR_DESTINO="$HOME/backups-rotatorios-atlas/backups"        # Dónde se guardan las copias
LOG_FILE="$HOME/backups-rotatorios-atlas/logs/ejecucion.log" # Archivo de registro
DIAS_RETENCION=7                                            # Días que se conserva cada copia
UMBRAL_DISCO_MAX=90                                         # % de disco usado a partir del cual no se hace backup
```

> El archivo se carga con `source`, o sea que se ejecuta como código Bash. Ponele permisos restrictivos y no pongas nada que no sea asignación de variables.

## ▶️ Uso

**Hacer un backup:**

```bash
./src/backup.sh
```

**Verificar la integridad de todos los backups:**

```bash
./src/verificar.sh
```

### Códigos de salida

| Script | Código | Significado |
| --- | --- | --- |
| `backup.sh` | `0` | Backup creado y firmado |
| `backup.sh` | `2` | Error crítico (falta configuración, origen inexistente, disco lleno, falló `tar`) |
| `verificar.sh` | `0` | Todas las firmas coinciden |
| `verificar.sh` | `1` | Al menos un backup está corrupto o modificado |
| `verificar.sh` | `2` | Error crítico (falta configuración o carpeta de destino) |

## ⏰ Automatizar con cron

Para correr el backup todos los días a las 02:00 y verificar a las 02:30, ejecutá `crontab -e` y agregá (con rutas absolutas):

```cron
0 2 * * *  /home/USUARIO/backups-rotatorios-atlas/src/backup.sh
30 2 * * * /home/USUARIO/backups-rotatorios-atlas/src/verificar.sh >> /home/USUARIO/backups-rotatorios-atlas/logs/verificacion.log 2>&1
```

Reemplazá `USUARIO` por tu usuario. Para ver las tareas cargadas: `crontab -l`.

## ♻️ Restaurar un backup

Un backup que nunca se restauró no es un backup. Probá la restauración así:

```bash
# 1. Verificar que la copia que vas a usar esté íntegra
cd backups
sha256sum -c backup_atlas_AAAA-MM-DD_HH-MM-SS.tar.gz.sha256

# 2. Ver qué contiene, sin extraer nada
tar -tzf backup_atlas_AAAA-MM-DD_HH-MM-SS.tar.gz | head

# 3. Extraer en una carpeta aparte (nunca encima del original)
mkdir -p ~/restauracion
tar -xzf backup_atlas_AAAA-MM-DD_HH-MM-SS.tar.gz -C ~/restauracion
```

Si el paso 1 imprime `OK`, la copia está íntegra.

## 🧠 Decisiones de diseño

- **Atómico con `.tmp` + `mv`:** un corte de luz en medio de la compresión no deja un `.tar.gz` roto que parezca válido.
- **Hash con ruta relativa:** el archivo `.sha256` no guarda rutas del usuario, así que es portable y no filtra datos de la máquina.
- **Rotación por prefijo:** el patrón `backup_atlas_*` evita borrar archivos ajenos si la carpeta de destino se comparte.
- **Configuración separada del código:** cambiar rutas o retención no requiere tocar los scripts.

## 📄 Licencia

MIT. Ver [LICENSE](LICENSE).
