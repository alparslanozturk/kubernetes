# Set up a Highly Available Kubernetes Cluster using kubeadm
Follow this documentation to set up a highly available Kubernetes cluster using __Debian GNU/Linux 11 (bullseye)__.

This documentation guides you in setting up a cluster with two master nodes, one worker node and a load balancer node using HAProxy.

## Vagrant Environment
|Role|FQDN|IP|OS|RAM|CPU|
|----|----|----|----|----|----|
|Load Balancer|loadbalancer.example.com|2.2.2.100|Debian 11|1G|1|
|Master|kmaster1.example.com|2.2.2.101|Debian 11|2G|2|
|Master|kmaster2.example.com|2.2.2.102|Debian 11|2G|2|
|Worker|kworker1.example.com|2.2.2.201|Debian 11|1G|1|

> * Password for the **root** account on all these virtual machines is **parola**
> * Perform all the commands as root user unless otherwise specified

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
apt update && apt install -y haproxy
```
##### Configure haproxy
Append the below lines to **/etc/haproxy/haproxy.cfg**
```
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
                server kmaster1 2.2.2.101:6443
                server kmaster2 2.2.2.102:6443
```
##### Restart haproxy service
```
systemctl restart haproxy
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
## On any one of the Kubernetes master node (Eg: kmaster1)
##### Initialize Kubernetes Cluster
First I prefared name instead of IP. So add /etc/hosts these config;
```
cat >> /etc/hosts<<EOF
2.2.2.101 loadbalancer.ornek.com loadbalancer
2.2.2.101 kmaster1.ornek.com kmaster1
2.2.2.102 kmaster2.ornek.com kmaster2
2.2.2.103 kworker1.ornek.com kworker1
EOF
```
After finish "kubeadm init ..."  change first line of hosts file. loadbalancer ip address: ``` 2.2.2.100 loadbalancer.ornek.com loadbalancer ```

```
kubeadm init --control-plane-endpoint="loadbalancer.ornek.com:6443" --upload-certs --apiserver-advertise-address=2.2.2.101
```
Copy the commands to join other master nodes and worker nodes. check commands;
````
curl -isk https://2.2.2.100:6443/healthz
````
```
curl -isk https://2.2.2.101:6443/healthz
````
##### Deploy Weave network
```
curl -sSL "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.32.0.0/12" > weave.yaml
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f weave.yaml
```

## Join other nodes to the cluster (kmaster2 & kworker1)
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
```

Have Fun!!
