#!/bin/bash
set -e

# Update system and install dependencies
yum update -y
yum install -y wget tar

#-----------------------------
# Install Node Exporter
#-----------------------------
NODE_EXPORTER_VER="1.7.0"
useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/node_exporter-${NODE_EXPORTER_VER}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VER}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VER}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

#-----------------------------
# Install Prometheus
#-----------------------------
PROMETHEUS_VER="2.52.0"
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VER}/prometheus-${PROMETHEUS_VER}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VER}.linux-amd64.tar.gz

cp prometheus-${PROMETHEUS_VER}.linux-amd64/prometheus /usr/local/bin/
cp prometheus-${PROMETHEUS_VER}.linux-amd64/promtool /usr/local/bin/
cp -r prometheus-${PROMETHEUS_VER}.linux-amd64/consoles /etc/prometheus
cp -r prometheus-${PROMETHEUS_VER}.linux-amd64/console_libraries /etc/prometheus

cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ['localhost:9100']
EOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/ \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

#-----------------------------
# Install Grafana
#-----------------------------
cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana OSS
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF

yum install -y grafana
systemctl enable grafana-server
systemctl start grafana-server

echo "Prometheus, Node Exporter, and Grafana installation completed!"