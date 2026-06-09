#!/usr/bin/env bash
set -euo pipefail

# Generates a Mosquitto password file at mosquitto/config/passwordfile
# Usage: ./scripts/create_mosquitto_password.sh [username] [password]

USERNAME=${1:-tomek}
PASSWORD=${2:-coder}
CONFIG_DIR=$(pwd)/mosquitto/config
MQTT_IMAGE=${MQTT_DOCKER_IMAGE:-eclipse-mosquitto:2.0.22}

echo "Creating password file for user '$USERNAME' in $CONFIG_DIR/passwordfile"

docker run --rm -v "$CONFIG_DIR":/mosquitto/config "$MQTT_IMAGE" \
  mosquitto_passwd -b /mosquitto/config/passwordfile "$USERNAME" "$PASSWORD"

echo "Password file created: $CONFIG_DIR/passwordfile"
