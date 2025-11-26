#!/bin/bash
# ============================================================================
# SCRIPT 1 : install_base.sh
# Description : Installation des dépendances de base pour serveurs Minecraft
# Usage : sudo ./install_base.sh
# ============================================================================

echo "=== Mise à jour des paquets ==="
apt-get update

echo "=== Installation de Java 17 ==="
apt-get install -y openjdk-17-jre-headless

echo "=== Installation de screen ==="
apt-get install -y screen

echo "=== Installation de wget ==="
apt-get install -y wget

echo "=== Installation de curl ==="
apt-get install -y curl

echo "=== Création du répertoire principal ==="
mkdir -p /opt/gameservers
chown root:root /opt/gameservers
chmod 755 /opt/gameservers

echo "=== Création du répertoire de backups ==="
mkdir -p /opt/backups/minecraft
chown root:root /opt/backups/minecraft
chmod 755 /opt/backups/minecraft

echo "=== Configuration des limites système ==="
cat > /etc/security/limits.d/minecraft.conf << 'EOF'
# Limites pour les serveurs Minecraft
* soft nofile 65536
* hard nofile 65536
EOF

echo "=== Vérification de la version Java ==="
java -version

echo ""
echo "✓ Installation de base terminée avec succès !"
