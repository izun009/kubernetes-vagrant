#!/bin/bash

echo "[TASK 1] update hosts"
echo '192.168.56.100 master master' | tee -a /etc/hosts
init=2
stop=$1+1
for (( c=$init; c<=$stop; c++ ))
do
  worker="$(($c-1))"
  echo "192.168.56.$c worker$worker worker$worker" | tee -a /etc/hosts
done


echo "[TASK 2] Install docker"
export DEBIAN_FRONTEND=noninteractive 
apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >/dev/null 2>&1
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update -y
apt-cache policy docker-ce
apt-get install docker-ce -y

# add ccount to the docker group
usermod -aG docker vagrant

# Enable docker service
echo "[TASK 3] Enable and start docker service"
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker >/dev/null 2>&1
systemctl daemon-reload
systemctl restart docker

# Add sysctl settings
echo "[TASK 4] Add sysctl settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

# Disable swap
echo "[TASK 5] Disable SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# Install apt-transport-https pkg
echo "[TASK 6] Installing apt-transport-https pkg"
apt-get update && apt-get install -y apt-transport-https curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

ls -ltr /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

# Install Kubernetes
echo "[TASK 7] Install Kubernetes kubeadm, kubelet and kubectl"
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Start and Enable kubelet service
echo "[TASK 8] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
systemctl start kubelet >/dev/null 2>&1

