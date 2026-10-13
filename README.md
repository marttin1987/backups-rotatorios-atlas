# 💾 Backups Rotatorios ATLAS

Sistema de almacenamiento, compresión, verificación de integridad e higiene de copias de seguridad automatizadas en servidores Linux.

## 📋 Características
- **Compresión Atómica**: Generación de paquetes `.tar.gz` previa prueba en archivo `.tmp` para evitar dejar respaldos corruptos en el sistema.
- **Validación de Integridad Portátil**: Firma criptográfica SHA-256 con rutas relativas para preservar la privacidad de usuarios locales.
- **Auditoría de Firma**: Script `src/verificar.sh` para comprobar la validez de los backups en cualquier momento.
- **Higiene Específica de Disco**: Purga de archivos antiguos filtrada únicamente por el prefijo `backup_atlas_*` para no borrar datos externos del usuario.
- **Detección Temprana de Parámetros**: Validación completa de las 5 variables en `config/backup.conf` y control de umbral crítico de almacenamiento.

## 🛠️ Requisitos e Instalación

1. Clonar el repositorio:
```bash
git clone git@github.com:marttin1987/backups-rotatorios-atlas.git
cd backups-rotatorios-atlas
