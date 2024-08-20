#!/bin/bash
# SteamCMD Base Installation Script
# Server Files: /mnt/server
# Image to install with is 'mono:latest'

# Update package list and install required packages
apt-get update -y
apt-get install -y --no-install-recommends \
    curl lib32gcc-s1 ca-certificates wget unzip x11vnc i3 xvfb

# Set default steam user if not provided
if [ -z "${STEAM_USER}" ]; then
    echo "Steam user is not set. Using anonymous user."
    STEAM_USER="anonymous"
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo "User set to ${STEAM_USER}"
fi

# Set up SteamCMD directory
STEAMCMD_DIR="/mnt/server/steamcmd"
mkdir -p "${STEAMCMD_DIR}"
chown -R root:root /mnt

# Set HOME environment variable
export HOME="/mnt/server"

# Download and install SteamCMD
curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C "${STEAMCMD_DIR}"
cd "${STEAMCMD_DIR}"

# Install the game using SteamCMD
./steamcmd.sh +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_AUTH}" +force_install_dir /mnt/server +app_update "${SRCDS_APPID}" validate +quit

# Set up Steam client libraries
STEAM_SDK_DIR="/mnt/server/.steam"
mkdir -p "${STEAM_SDK_DIR}/sdk32" "${STEAM_SDK_DIR}/sdk64"
cp -v "${STEAMCMD_DIR}/linux32/steamclient.so" "${STEAM_SDK_DIR}/sdk32/steamclient.so"
cp -v "${STEAMCMD_DIR}/linux64/steamclient.so" "${STEAM_SDK_DIR}/sdk64/steamclient.so"

# Game-specific setup
CONFIG_DIR="/mnt/server/.config"
STORAGE_DIR="/mnt/server/storage"
MODS_DIR="/mnt/server/Mods"
LOGS_DIR="/mnt/server/logs"

mkdir -p "${CONFIG_DIR}/i3" "${CONFIG_DIR}/StardewValley" "${STORAGE_DIR}" "${MODS_DIR}" "${LOGS_DIR}"

# Download and install SMAPI
SMAPI_URL="https://github.com/Pathoschild/SMAPI/releases/download/3.8/SMAPI-3.8.0-installer.zip"
SMAPI_INSTALLER="${STORAGE_DIR}/nexus.zip"
wget -qO "${SMAPI_INSTALLER}" "${SMAPI_URL}"
unzip "${SMAPI_INSTALLER}" -d /mnt/server/nexus
echo -e "2\n/mnt/server\n1\n" | mono /mnt/server/nexus/SMAPI\ 3.8.0\ installer/internal/unix-install.exe

# Download and set up configuration files
CONFIG_BASE_URL="https://raw.githubusercontent.com/NerdsCorp/pelican-server-stardew-valley/main"
wget -qO "${CONFIG_DIR}/StardewValley/startup_preferences" "${CONFIG_BASE_URL}/stardew_valley_server.config"
wget -qO "${CONFIG_DIR}/i3/config" "${CONFIG_BASE_URL}/i3.config"

# Download, unzip, and configure mods
declare -A MODS=(
    ["alwayson.zip"]="${CONFIG_BASE_URL}/alwayson.zip"
    ["unlimitedplayers.zip"]="${CONFIG_BASE_URL}/unlimitedplayers.zip"
    ["autoloadgame.zip"]="${CONFIG_BASE_URL}/autoloadgame.zip"
)
for mod in "${!MODS[@]}"; do
    wget -qO "${STORAGE_DIR}/${mod}" "${MODS[$mod]}"
    unzip "${STORAGE_DIR}/${mod}" -d "${MODS_DIR}"
done

# Configure each mod
declare -A MOD_CONFIGS=(
    ["Always On Server/config.json"]="${CONFIG_BASE_URL}/alwayson.json"
    ["UnlimitedPlayers/config.json"]="${CONFIG_BASE_URL}/unlimitedplayers.json"
    ["AutoLoadGame/config.json"]="${CONFIG_BASE_URL}/autoloadgame.json"
)
for config in "${!MOD_CONFIGS[@]}"; do
    wget -qO "${MODS_DIR}/${config}" "${MOD_CONFIGS[$config]}"
done

# Download and set up the Stardew Valley server script
wget -qO /mnt/server/stardew-valley-server.sh "${CONFIG_BASE_URL}/stardew-valley-server.sh"
chmod +x /mnt/server/stardew-valley-server.sh

# Cleanup
rm "${SMAPI_INSTALLER}" "${STORAGE_DIR}/alwayson.zip" "${STORAGE_DIR}/unlimitedplayers.zip" "${STORAGE_DIR}/autoloadgame.zip"

echo "Stardew Valley Installation complete. Restart the server."
