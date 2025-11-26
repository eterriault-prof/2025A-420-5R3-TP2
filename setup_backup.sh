# ============================================================================
# SCRIPT 3 : setup_backup.sh
# Description : Configuration des backups automatiques pour un serveur
# Usage : sudo ./setup_backup.sh <nom_serveur> <heure> <retention_jours>
# Exemple : sudo ./setup_backup.sh survival01 2 7
# ============================================================================

#!/bin/bash

# Récupération des paramètres
SERVER_NAME=$1
BACKUP_HOUR=$2
RETENTION_DAYS=$3

# Vérification des paramètres
if [ -z "$SERVER_NAME" ] || [ -z "$BACKUP_HOUR" ] || [ -z "$RETENTION_DAYS" ]; then
    echo "Usage: $0 <nom_serveur> <heure> <retention_jours>"
    echo "Exemple: $0 survival01 2 7"
    exit 1
fi

echo "=== Configuration du backup pour $SERVER_NAME ==="
echo "  - Heure d'exécution: ${BACKUP_HOUR}h00"
echo "  - Rétention: $RETENTION_DAYS jours"
echo ""

echo "=== Création du script de backup ==="
cat > /usr/local/bin/backup-$SERVER_NAME.sh << 'EOFSCRIPT'
#!/bin/bash
# Script de backup automatique pour SERVER_NAME_PLACEHOLDER

SERVER_NAME="SERVER_NAME_PLACEHOLDER"
SERVER_DIR="/opt/gameservers/${SERVER_NAME}/server"
BACKUP_DIR="/opt/backups/minecraft/${SERVER_NAME}"
RETENTION_DAYS=RETENTION_PLACEHOLDER
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${DATE}.tar.gz"

# Création du répertoire de backup
mkdir -p "${BACKUP_DIR}"

# Vérification que le serveur existe
if [ ! -d "$SERVER_DIR" ]; then
    echo "ERREUR: Le serveur $SERVER_NAME n'existe pas dans $SERVER_DIR"
    exit 1
fi

echo "Début du backup de $SERVER_NAME"

# Création de l'archive
cd "$SERVER_DIR"
tar -czf "${BACKUP_FILE}" world server.properties 2>/dev/null

# Vérification que le backup a réussi
if [ $? -eq 0 ]; then
    echo "Backup créé: ${BACKUP_FILE}"
    
    # Nettoyage des anciens backups
    echo "Nettoyage des backups de plus de ${RETENTION_DAYS} jours..."
    find "${BACKUP_DIR}" -name "backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
    
    echo "Backup terminé avec succès"
else
    echo "ERREUR: Le backup a échoué"
    exit 1
fi
EOFSCRIPT

# Remplacement des placeholders
sed -i "s/SERVER_NAME_PLACEHOLDER/$SERVER_NAME/g" /usr/local/bin/backup-$SERVER_NAME.sh
sed -i "s/RETENTION_PLACEHOLDER/$RETENTION_DAYS/g" /usr/local/bin/backup-$SERVER_NAME.sh

# Permissions d'exécution
chmod 750 /usr/local/bin/backup-$SERVER_NAME.sh
chown root:root /usr/local/bin/backup-$SERVER_NAME.sh

echo "=== Configuration de la tâche cron ==="
# Ajout de la ligne cron pour root
CRON_LINE="0 $BACKUP_HOUR * * * /usr/local/bin/backup-$SERVER_NAME.sh >> /var/log/backup-$SERVER_NAME.log 2>&1"

# Vérifier si la ligne existe déjà
if ! crontab -l 2>/dev/null | grep -q "backup-$SERVER_NAME.sh"; then
    # Ajouter la ligne
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    echo "Tâche cron ajoutée pour $SERVER_NAME"
else
    echo "Tâche cron déjà existante pour $SERVER_NAME"
fi

echo ""
echo "✓ Configuration du backup terminée !"
echo "  - Script: /usr/local/bin/backup-$SERVER_NAME.sh"
echo "  - Planification: Tous les jours à ${BACKUP_HOUR}h00"
echo "  - Rétention: $RETENTION_DAYS jours"
echo "  - Log: /var/log/backup-$SERVER_NAME.log"
