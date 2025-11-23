#!/usr/bin/env bash
set -euo pipefail

# ===== Initial settings =====
VERSION="2.53.4"
ARCH="linux-amd64"
PROM_USER="prometheus"
PROM_GROUP="prometheus"
TMP_DIR="/tmp"
INSTALL_DIR="/usr/local/bin"
ETC_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"

echo "==> Installing Prometheus v$VERSION ($ARCH)"

cd "$TMP_DIR"

TAR_FILE="prometheus-${VERSION}.${ARCH}.tar.gz"
EXTRACT_DIR="prometheus-${VERSION}.${ARCH}"

# ===== Download Prometheus if not already downloaded =====
if [ ! -f "$TAR_FILE" ]; then
  echo "==> Downloading Prometheus..."
  wget "https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${TAR_FILE}"
else
  echo "==> Tar file already exists, using existing file."
fi

# ===== Extract the package =====
if [ ! -d "$EXTRACT_DIR" ]; then
  echo "==> Extracting tar file..."
  tar -xvf "$TAR_FILE"
fi

cd "$EXTRACT_DIR"

# ===== Create Prometheus user and group =====
echo "==> Creating user/group '${PROM_USER}' if they do not exist..."
if ! getent group "$PROM_GROUP" >/dev/null 2>&1; then
  groupadd --system "$PROM_GROUP"
fi

if ! id -u "$PROM_USER" >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /bin/false -g "$PROM_GROUP" "$PROM_USER"
fi

# ===== Install binaries =====
echo "==> Copying binaries to ${INSTALL_DIR} ..."
cp prometheus promtool "$INSTALL_DIR/"

chown "$PROM_USER:$PROM_GROUP" "$INSTALL_DIR/prometheus"
chown "$PROM_USER:$PROM_GROUP" "$INSTALL_DIR/promtool"

# ===== Set up config and console files =====
echo "==> Setting configuration directory at ${ETC_DIR} ..."
mkdir -p "$ETC_DIR"

cp prometheus.yml "$ETC_DIR/"
cp -r consoles "$ETC_DIR/"
cp -r console_libraries "$ETC_DIR/"

chown -R "$PROM_USER:$PROM_GROUP" "$ETC_DIR"

# ===== Create data directory =====
echo "==> Creating data directory at ${DATA_DIR} ..."
mkdir -p "$DATA_DIR"
chown -R "$PROM_USER:$PROM_GROUP" "$DATA_DIR"

# ===== Create systemd service file =====
echo "==> Creating systemd service at /etc/systemd/system/prometheus.service ..."
cat >/etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ===== Reload systemd and start service =====
echo "==> Reloading systemd ..."
systemctl daemon-reload

echo "==> Enabling Prometheus service on boot ..."
systemctl enable prometheus

echo "==> Starting Prometheus ..."
systemctl start prometheus

echo "==> Prometheus service status:"
systemctl status prometheus --no-pager
