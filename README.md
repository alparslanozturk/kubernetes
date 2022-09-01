# kubernetes
Kubernetes playground


1. With Haproxy and Kubeadm setup kuberntes multimaster cluster by using vagrant ( vmware provider )
2. Statefull sets, persistent volumes 
3. https://prometheus.io/docs/prometheus/latest/federation/
4. 



### keep running maven docker 


maven dokuman :  https://maven.apache.org/guides/introduction/introduction-to-archetypes.html

```

docker run  -d --rm --name maven --hostname maven  maven sleep infinity

yada 

docker run -d --rm --name maven --hostname maven  maven tail -f /dev/null


docker exec -it maven bash 

$ mvn archetype:generate
...
```



###  vagrant box 

1. create "vagrant" user with password "vagrant"
2. add sudo to /etc/sudoers file ```vagrant ALL=(ALL) NOPASSWD:ALL```
3. add key https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub to ~/.ssh/authorized_keys
4. vmware: 
```
vmware-vdiskmanager -d box.vmdk
vmware-vdiskmanager -k box.vmdk
rm logs files. 

cat > ./metadata.json <<EOF
{
  "provider": "vmware_desktop"
}
EOF

tar cvzf myboxfile.box ./*
vagrant box add mybox myboxfile.box
```
5. test with 
```
vagrant init mybox 
vagrant up
```
6. uploading....

https://app.vagrantup.com/alparslanozturk

sample:
![resim](https://user-images.githubusercontent.com/9527118/187871158-84135ccc-d1cf-478a-8eb4-cedd4556f244.png)



