# Set up a Highly Available Kubernetes Cluster using kubeadm
Follow this documentation to set up a highly available Kubernetes cluster using __Debian GNU/Linux 11 (bullseye)__.

This documentation guides you in setting up a cluster with three master nodes, one worker node and two load balancer node using HAProxy.

## Vagrant Environment
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Load Balancer|lb1.example.com|2.2.2.11|Debian 11|512M|1|
|Load Balancer|lb2.example.com|2.2.2.12|Debian 11|512M|1|
|Master|master1.example.com|2.2.2.21|Debian 11|2G|2|
|Master|master2.example.com|2.2.2.22|Debian 11|2G|2|
|Master|master3.example.com|2.2.2.23|Debian 11|2G|2|
|Worker|worker1.example.com|2.2.2.31|Debian 11|1G|1|

> * Password for the **root** account on all these virtual machines is **parola**
> * Perform all the commands as root user unless otherwise specified
> * keepalived monitor only haproxy service and cariers only vip ip(2.2.2.10) between LBs

### Virtual IP managed by Keepalived on the load balancer nodes
|Virtual IP|
|----|
|2.2.2.10|

## Pre-requisites
If you want to try this in a virtualized environment on your workstation
* Vmware Workstation installed
* Vagrant installed
* Vagrant Vmware provider & plugin installed
* Microsoft Windows openSSH feature installed 
* Host machine has atleast 8 cores
* Host machine has atleast 8G memory
## Start vagrant vagrant-vmware-utility
```
net start vagrant-vmware-utility
```
## Bring up all the virtual machines
```
vagrant up
```

## Set up load balancer node
##### Install Haproxy
```
apt update && apt install -y keepalived haproxy
```
##### Configure keepalived
Append the below lines to **/etc/keepalived/keepalived.conf**
```
cat > /etc/keepalived/keepalived.conf <EOF
global_defs {
    script_user root
    enable_script_security
}
vrrp_script check_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
}
vrrp_instance VI_HAPROXY {
    state MASTER
    #interface ens32
    virtual_router_id 51
    priority 100
    virtual_ipaddress {
        2.2.2.10
    }
    track_script {
        check_haproxy
    }
}
EOF
```
##### Configure haproxy
Append the below lines to **/etc/haproxy/haproxy.cfg**
```
cat >> /etc/haproxy/haproxy.cfg <<EOF
listen stats
        mode http
        bind *:80
        stats enable
        stats uri /

listen kubernetes-api
        mode tcp
        bind *:6443
        option tcplog
        option httpchk GET /healthz HTTP/2
        http-check expect status 200
        option ssl-hello-chk
        balance roundrobin
        default-server check inter 2s fall 3 rise 2
                server master1 2.2.2.11:6443
                server master2 2.2.2.12:6443
                server master3 2.2.2.13:6443
EOF
```
##### Restart haproxy service
```
systemctl enable --now haproxy keepalived
```

### Kubernetes Setup

##### Install docker engine: https://docs.docker.com/engine/install/debian/
```
{
  apt-get install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update && apt-get -y install docker-ce docker-ce-cli containerd.io
}
```

##### Add Apt repository: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
```
{
  apt-get install -y apt-transport-https ca-certificates curl
  curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
}
```
##### Install Kubernetes components
```
apt-get update && apt-get install -y kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl
```
## On any one of the Kubernetes master node (Eg: master1)
##### Initialize Kubernetes Cluster
```
kubeadm init --control-plane-endpoint="loadbalancer.ornek.com:6443" --upload-certs --apiserver-advertise-address=2.2.2.11
```
Copy the commands to join other master nodes and worker nodes. check commands;
````
curl -isk https://2.2.2.10:6443/healthz
````
```
curl -isk https://2.2.2.11:6443/healthz
````
##### Deploy Weave network
```
curl -sSL "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.32.0.0/12" > weave.yaml
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f weave.yaml
```

## Join other nodes to the cluster (master2 & worker1)
> Use the respective kubeadm join commands you copied from the output of kubeadm init command on the first master.

> IMPORTANT: You also need to pass --apiserver-advertise-address to the join command when you join the other master node.

## Downloading kube config to your local machine
On your host machine
```
mkdir ~/.kube
scp root@2.2.2.101:/etc/kubernetes/admin.conf ~/.kube/config-vagrant
export KUBECONFIG=~/.kube/config-vagrant
```
Password for root account is kubeadmin (if you used my Vagrant setup)

## Verifying the cluster
```
kubectl cluster-info
kubectl get nodes
kubectl get cs
or 
kubectl drain master1 --ignore-daemonsets --delete-emptydir-data
kubectl delete node master1

```

Have Fun!!
