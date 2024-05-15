#!/bin/bash

echo "[TASK 1] Edit containerd"
sudo rm /etc/containerd/config.toml
sudo bash -c 'cat <<EOF >> /etc/containerd/config.toml
# Copyright 2018-2022 Docker Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

enabled_plugins = ["cri"]
[plugins."io.containerd.grpc.v1.cri".containerd]
  endpoint = "unix:///var/run/containerd/containerd.sock"


#root = "/var/lib/containerd"
#state = "/run/containerd"
#subreaper = true
#oom_score = 0

#[grpc]
#  address = "/run/containerd/containerd.sock"
#  uid = 0
#  gid = 0

#[debug]
#  address = "/run/containerd/debug.sock"
#  uid = 0
#  gid = 0
#  level = "info"
EOF'

sudo systemctl restart containerd

# Initialize Kubernetes
echo "[TASK 2] Initialize Kubernetes Cluster"
sudo kubeadm init --apiserver-advertise-address=192.168.56.100 --pod-network-cidr=10.244.0.0/16

# Copy Kube admin config
echo "[TASK 3] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy flannel network
echo "[TASK 4] Deploy flannel network"
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

# Generate Cluster join command
echo "[TASK 5] Generate and save cluster join command to /vagrant/joincluster.sh"
sudo kubeadm token create --print-join-command > /vagrant/joincluster.sh 2>/dev/null
