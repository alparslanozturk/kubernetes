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
