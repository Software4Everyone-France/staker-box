#!/bin/sh

installDir=$PWD

mkdir ~/.ssh
cat id_rsa.pub >> ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys

sudo timedatectl set-timezone Europe/Paris

## GETH
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install ethereum -y

sudo apt install net-tools

sudo adduser --home /home/geth --disabled-password --gecos 'Go Ethereum Client' geth

sudo cp "${installDir}"/geth.service /etc/systemd/system/geth.service

sudo systemctl daemon-reload
#sudo systemctl enable geth
#sudo systemctl start geth

echo "BEACON"

## BEACON
sudo adduser --home /home/beacon --disabled-password --gecos 'Ethereum 2 Beacon Chain' beacon
sudo -u beacon mkdir /home/beacon/bin
sudo -u beacon mkdir /home/beacon/conf

sudo cp "${installDir}"/conf/beacon/* /home/beacon/conf/
sudo chown beacon:beacon /home/beacon/conf/*

sudo cp "${installDir}"/*-beacon-chain.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/*-beacon-chain.service

echo "VALIDATOR"

## VALIDATOR
sudo adduser --home /home/validator --disabled-password --gecos 'Ethereum 2 Validator' validator
sudo -u validator mkdir /home/validator/bin
sudo -u validator mkdir /home/validator/conf

sudo cp "${installDir}"/conf/validator/* /home/validator/conf/
sudo chown validator:validator /home/validator/conf/*

sudo cp "${installDir}"/*-validator.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/*-validator.service

echo "SLASHER"

## SLASHER
sudo adduser --home /home/slasher --disabled-password --gecos 'Ethereum 2 Slasher' slasher
sudo -u slasher mkdir /home/slasher/bin
sudo -u slasher mkdir /home/slasher/conf

sudo cp "${installDir}"/prysm-slasher.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/prysm-slasher.service

echo "Monitoring"

## MONITORING

sudo adduser --system prometheus --group --no-create-home

cd || exit
wget https://github.com/prometheus/prometheus/releases/download/v2.22.1/prometheus-2.22.1.linux-amd64.tar.gz
tar xzvf prometheus-2.22.1.linux-amd64.tar.gz
cd prometheus-2.22.1.linux-amd64 || exit
sudo cp promtool /usr/local/bin/
sudo cp prometheus /usr/local/bin/
sudo chown root.root /usr/local/bin/promtool /usr/local/bin/prometheus
sudo chmod 755 /usr/local/bin/promtool /usr/local/bin/prometheus
cd || exit
rm prometheus-2.22.1.linux-amd64.tar.gz

sudo mkdir -p /etc/prometheus/console_libraries /etc/prometheus/consoles /etc/prometheus/files_sd /etc/prometheus/rules /etc/prometheus/rules.d

sudo cp "${installDir}"/prometheus.yml /etc/prometheus/prometheus.yml
sudo chown -R prometheus.prometheus /etc/prometheus

sudo mkdir /var/lib/prometheus
sudo chown prometheus.prometheus /var/lib/prometheus
sudo chmod 755 /var/lib/prometheus

sudo cp "${installDir}"/prometheus.service /etc/systemd/system/prometheus.service
sudo chown root:root /etc/systemd/system/prometheus.service

sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service

cd || exit
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt-get update
sudo apt-get install grafana-enterprise

sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

## NODE EXPORTER

echo "Node exporter"

sudo adduser --system node_exporter --group --no-create-home

cd || exit
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
tar xzvf node_exporter-1.0.1.linux-amd64.tar.gz
sudo cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm node_exporter-1.0.1.linux-amd64.tar.gz

sudo cp ${installDir}/node_exporter.service /etc/systemd/system/node_exporter.service
sudo chown root:root /etc/systemd/system/node_exporter.service

sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service

## BLACKBOX EXPORTER

echo "blackbox"

sudo adduser --system blackbox_exporter --group --no-create-home

cd || exit
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.18.0/blackbox_exporter-0.18.0.linux-amd64.tar.gz
tar xvzf blackbox_exporter-0.18.0.linux-amd64.tar.gz
sudo cp blackbox_exporter-0.18.0.linux-amd64/blackbox_exporter /usr/local/bin/
sudo chown blackbox_exporter.blackbox_exporter /usr/local/bin/blackbox_exporter
sudo chmod 755 /usr/local/bin/blackbox_exporter

sudo setcap cap_net_raw+ep /usr/local/bin/blackbox_exporter
rm blackbox_exporter-0.18.0.linux-amd64.tar.gz

sudo mkdir /etc/blackbox_exporter
sudo chown blackbox_exporter.blackbox_exporter /etc/blackbox_exporter

sudo cp "${installDir}"/blackbox.yml /etc/blackbox_exporter/blackbox.yml
sudo chown blackbox_exporter.blackbox_exporter /etc/blackbox_exporter/blackbox.yml

sudo cp "${installDir}"/blackbox_exporter.service /etc/systemd/system/blackbox_exporter.service
sudo chown root:root /etc/systemd/system/blackbox_exporter.service

sudo systemctl daemon-reload
sudo systemctl start blackbox_exporter.service
sudo systemctl enable blackbox_exporter.service

## ETH2STATS

echo "eth2stats"

sudo adduser --system eth2stats --group --no-create-home

sudo mkdir /var/lib/eth2stats-prysm /var/lib/eth2stats-lighthouse /var/lib/eth2stats-teku /var/lib/eth2stats-nimbus /var/lib/eth2stats-lodestar
sudo chown eth2stats.eth2stats /var/lib/eth2stats*
sudo chmod 755 /var/lib/eth2stats*

sudo cp "${installDir}"/eth2stats-*.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/eth2stats-*.service

sudo cp "${installDir}"/eth2stats-client /usr/local/bin
sudo chown root.root /usr/local/bin/eth2stats-client
sudo chmod 755 /usr/local/bin/eth2stats-client

sudo systemctl daemon-reload
