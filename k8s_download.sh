#!/bin/bash
# Program:
#	Download docker and k8s which is v1.29
# History: 
# 2024/06/23 DieWay

# Install the Essetial Packages
sudo apt update
sudo apt install -y curl apt-transport-https ca-certificates software-properties-common gpg

# Add Docker's apt repository
sudo apt update
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# check avaiable version
# apt-cache madison docker-ce | awk '{ print $3 }'

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# Download specific version docker
VERSION_STRING=5:25.0.3-1~ubuntu.20.04~focal
sudo apt install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

#Check if download succeed
sudo usermod -aG docker $USER #將user加入docker群組，之後就不用在打docker指令前打sudo
sudo systemctl start docker
sudo systemctl enable docker
sudo docker version
systemctl status --no-pager docker

# Docker Config
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

# Add Repo
# 版本1.29，若要修改版本則curl gpg key和deb的時候要修改v1.29到需要的版本
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# Install k8s
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo apt install -y kubelet kubectl kubeadm
sudo apt-mark hold kubelet kubeadm kubectl
sudo sed -i 's/disabled_plugins/#disabled_plugins/g' /etc/containerd/config.toml
sudo systemctl restart containerd.service
exit 0
