#!/bin/bash

### host file 
cat >> /etc/hosts<<EOF
2.2.2.10 loadbalancer.ornek.com loadbalancer
2.2.2.11 lb1.ornek.com lb1
2.2.2.12 lb2.ornek.com lb2
2.2.2.21 kmaster1.ornek.com kmaster1
2.2.2.22 kmaster2.ornek.com kmaster2
2.2.2.23 kmaster3.ornek.com kmaster3
2.2.2.31 kworker1.ornek.com kworker1
EOF
sed -i '/^127.0.2.1 .*/d' /etc/hosts

### vim install 
apt update && apt install -y vim 

###Disable ipv6
cat <<EOF | sudo tee /etc/sysctl.d/ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
sysctl --system

###Kubernetes modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

###Kubernetes sysctl.conf
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

###Docker
mkdir /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

###Disable swap
swapoff -a; sed -i '/swap/d' /etc/fstab

###Enable ssh password authentication
sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl reload sshd

###Set Root password
echo -e "parola\nparola" | passwd root >/dev/null 2>&1
