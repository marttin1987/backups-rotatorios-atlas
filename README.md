# 💾 Backups Rotatorios ATLAS

Sistema de almacenamiento, compresión, verificación de integridad e higiene de copias de seguridad automatizadas en servidores Linux.

## 📋 Características
- **Comprension Atomica**: Generacion de paquetes `.tar.gz` previa prueba en archivo `.tmp` para evitar dejar respaldos corruptos en el sistema
- **Validacion de Integridad Portatil**: Firma criptografica SHA-256 con rutas relativas para preservar la privacidad de usuario locales.
- **Auditoria de firma**: Script `src/verificar.sh` para comprobar la validez de los backups en cualquier momento.
- **Higiene Especifica de Disco**: Purga de archivos antiguos filtrada unicamente por el prefijo `backup_atlas_*` para no borrar datos externos del usuario.
- **Verificacion de Parametros**: Deteccion temprana de faltantes en `config/backup.conf` y control de umbral critico de almacenamiento.


## 🛠️ Requisitos e Instalación

1. Clonar el repositorio:
```bash
git clone git@github.com:marttin1987/backups-rotatorios-atlas.git
cd backups-rotatorios-atlas
