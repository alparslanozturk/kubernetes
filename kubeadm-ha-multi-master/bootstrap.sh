#!/bin/bash

# Disable ipv6
echo  "[TASK 0] Disabling IPv6"
echo "net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
      net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# Disable ufw
echo "TASK 0] Disabling ufw"
ufw disable 
systemctl  disable --now multipathd


# Enable ssh password authentication
echo "[TASK 1] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

# Set Root password
echo "[TASK 2] Set root password"
echo -e "parola\nparola" | passwd root >/dev/null 2>&1
