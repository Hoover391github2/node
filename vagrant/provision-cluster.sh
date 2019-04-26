#!/bin/bash -e

if [ $EUID -eq 0 ]; then
  echo "I'm root, switching to vagrant."
  exec sudo -iu vagrant bash $0
fi

echo "Hello, my name is $(whoami)."

echo "Preparing the system"

sudo apt-get update -qq
sudo apt-get install -yqq git python3 unzip docker.io supervisor python3-venv
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.d/es.conf
sudo sysctl --system
sudo adduser vagrant docker
sg docker newgrp `id -gn`
sudo chown vagrant /opt


echo "Installing the nomad cluster"

git clone https://github.com/liquidinvestigations/cluster /opt/cluster
cd /opt/cluster

cat > cluster.ini <<EOF
[nomad]
address = 0.0.0.0
[vault]
disable_mlock = true
EOF

./cluster.py install
./cluster.py configure
sudo ln -s `pwd`/etc/supervisor-cluster.conf /etc/supervisor/conf.d/cluster.conf
sudo supervisorctl update

sudo supervisorctl start cluster:consul cluster:vault
./cluster.py autovault
sudo supervisorctl start cluster:nomad
