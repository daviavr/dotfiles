#!/bin/bash

# ==============================================================================
# Script to set up Kanata with a dedicated user and hardened systemd service
# ==============================================================================

# CONFIGURATION
#
# Kanata config file name, expected to live in the repo root (one level up from this script)
KANATA_CONFIG_NAME="config.kbd"

# System location where the kanata config file will be placed
# (DO NOT EDIT)
SYSTEM_KANATA_CONFIG_DST="/etc/kanata/config.kbd"

# Kanata version to download
KANATA_VERSION="v1.12.0"

# Dedicated user/group names
KANATA_USER="kanata"
UINPUT_GROUP="uinput"

# FUNCTION TO PRINT MESSAGES
echoinfo() {
    echo "[INFO] $1"
}
echoerror() {
    echo "[ERROR] $1" >&2
}

# CHECK FOR ROOT/SUDO
if [ "$(id -u)" -ne 0 ]; then
  echoerror "This script must be run with sudo or as root."
  exit 1
fi

# DETERMINE SOURCE CONFIG FILE PATH
# Resolve relative to the script's location, so it works regardless of $HOME or sudo context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_KANATA_CONFIG_SRC="$SCRIPT_DIR/$KANATA_CONFIG_NAME"

if [ ! -f "$USER_KANATA_CONFIG_SRC" ]; then
    echoerror "Kanata config file not found at: $USER_KANATA_CONFIG_SRC"
    echoerror "Please ensure '$KANATA_CONFIG_NAME' exists in the repository root (one level up from this script)."
    exit 1
fi

# If we reach here, USER_KANATA_CONFIG_SRC holds the validated path to the source config file
echoinfo "Using source config file: $USER_KANATA_CONFIG_SRC"

echoinfo "Starting Kanata hardened setup..."

#========================
# STEP 1: Create User/Group
#========================
echoinfo "Creating group '$UINPUT_GROUP' (if it doesn't exist)..."
groupadd "$UINPUT_GROUP" || echoinfo "Group '$UINPUT_GROUP' likely already exists."

echoinfo "Creating user '$KANATA_USER' (if it doesn't exist)..."
useradd --system --no-create-home --groups input,"$UINPUT_GROUP" --shell /bin/false --user-group "$KANATA_USER" || echoinfo "User '$KANATA_USER' likely already exists."

#========================
# STEP 2: Prepare Config Directory & Copy Config
#========================
echoinfo "Creating directory /etc/kanata..."
mkdir -p /etc/kanata

echoinfo "Copying Kanata config from $USER_KANATA_CONFIG_SRC to $SYSTEM_KANATA_CONFIG_DST..."
cp "$USER_KANATA_CONFIG_SRC" "$SYSTEM_KANATA_CONFIG_DST"
if [ $? -ne 0 ]; then
    echoerror "Failed to copy config file. Please check permissions and paths."
    exit 1
fi

#========================
# STEP 3: Set Config Permissions
#========================
echoinfo "Setting permissions on $SYSTEM_KANATA_CONFIG_DST..."
chown root:"$KANATA_USER" "$SYSTEM_KANATA_CONFIG_DST"
chmod 640 "$SYSTEM_KANATA_CONFIG_DST"

#========================
# STEP 4: Create udev Rule
#========================
echoinfo "Creating udev rule for /dev/uinput..."
echo "KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"$UINPUT_GROUP\", OPTIONS+=\"static_node=uinput\"" > /etc/udev/rules.d/50-kanata.rules

#========================
# STEP 5: Download and Install Kanata
#========================
KANATA_URL="https://github.com/jtroo/kanata/releases/download/${KANATA_VERSION}/linux-binaries-x64.zip"
KANATA_BIN_PATH="/usr/local/bin/kanata"
KANATA_TMP_DIR="$(mktemp -d)"
KANATA_TMP_ZIP="$KANATA_TMP_DIR/kanata-linux.zip"

echoinfo "Stopping kanata.service (if running) before download..."
systemctl stop kanata.service > /dev/null 2>&1 || true # Stop the service, ignore errors

echoinfo "Downloading Kanata ${KANATA_VERSION} from ${KANATA_URL}..."
# Use curl with -fSL to follow redirects, show errors, and fail silently on HTTP errors
curl -fSL -o "$KANATA_TMP_ZIP" "$KANATA_URL"
if [ $? -ne 0 ]; then
    echoerror "Failed to download Kanata. Check URL or network connection."
    exit 1
fi

echoinfo "Extracting kanata_linux_x64..."
unzip -o -j "$KANATA_TMP_ZIP" "kanata_linux_x64" -d "$KANATA_TMP_DIR"
if [ $? -ne 0 ]; then
    echoerror "Failed to extract Kanata binary from the downloaded archive."
    exit 1
fi

echoinfo "Installing binary to ${KANATA_BIN_PATH}..."
install -m 754 -o root -g "$KANATA_USER" "$KANATA_TMP_DIR/kanata_linux_x64" "$KANATA_BIN_PATH"

#========================
# STEP 6: Create Systemd Service Unit
#========================
echoinfo "Creating systemd service file /etc/systemd/system/kanata.service..."
# Use cat with EOF for cleaner multi-line definition
cat << EOF > /etc/systemd/system/kanata.service
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
Wants=modprobe@uinput.service
After=modprobe@uinput.service

[Service]
Type=simple
User=$KANATA_USER
Group=$KANATA_USER
ExecStart=$KANATA_BIN_PATH --quiet --cfg $SYSTEM_KANATA_CONFIG_DST
Restart=no
# Security
CapabilityBoundingSet=
DeviceAllow=/dev/uinput rw
DeviceAllow=char-input
DeviceAllow=/dev/stdin
DevicePolicy=strict
PrivateDevices=true
BindPaths=/dev/uinput
BindReadOnlyPaths=/dev/stdin
BindReadOnlyPaths=/dev/input/
InaccessiblePaths=/dev/shm
LockPersonality=true
NoNewPrivileges=true
PrivateTmp=true
PrivateNetwork=true
PrivateUsers=true
#ProtectClock=true # Disabled as per original example notes
ProtectHome=true
ProtectHostname=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectSystem=strict
ProtectControlGroups=true
RestrictAddressFamilies=AF_UNIX # Allow only Unix sockets, deny others like network
RestrictNamespaces=true
SystemCallArchitectures=native
SystemCallErrorNumber=EPERM
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources
RemoveIPC=true
IPAddressDeny=any
RestrictSUIDSGID=true
RestrictRealtime=true
MemoryDenyWriteExecute=true
UMask=0077

[Install]
WantedBy=multi-user.target
EOF

#========================
# STEP 7: SELinux file contexts (openSUSE with SELinux enforcing)
#========================
if command -v restorecon > /dev/null 2>&1 && [ "$(getenforce 2>/dev/null)" = "Enforcing" ]; then
    if ! command -v audit2allow > /dev/null 2>&1; then
        echoerror "SELinux is enforcing but 'audit2allow' is missing."
        echoerror "Install it with: zypper install policycoreutils-python-utils"
        exit 1
    fi

    echoinfo "Restoring default SELinux contexts on installed files..."
    restorecon -Rv /usr/local/bin/kanata /etc/kanata /etc/systemd/system/kanata.service /etc/udev/rules.d/50-kanata.rules
else
    echoinfo "SELinux not in enforcing mode (or tools absent), skipping relabeling."
fi

#========================
# STEP 8: Reload Systemd, Enable & Start Service
#========================
echoinfo "Reloading systemd daemon..."
systemctl daemon-reload

echoinfo "Enabling kanata.service..."
systemctl enable kanata.service

echoinfo "Starting/Restarting kanata.service..."
systemctl restart kanata.service

echoinfo "-----------------------------------------------------"
echoinfo "Kanata setup script finished!"
echoinfo "Please REBOOT your system for all changes (especially udev rules) to take effect properly."
echoinfo "After rebooting, check status with: systemctl status kanata.service"
echoinfo "If the service fails on SELinux, inspect denials with:"
echoinfo "  ausearch -m avc -ts recent | audit2allow -R"
echoinfo "-----------------------------------------------------"

exit 0

