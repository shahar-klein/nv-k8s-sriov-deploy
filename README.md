
```
Control/Data
             +---------+---------------------+------------------+--------------------GW/10.50.55.1
                       |                     |                  |
                       |                     |                  |
                       |                     |                  |
                 +-----+-----+        +------+----+       +-----+-----+
                 | master-06 |        | node-09   |       |node-12    |
                 | 10.50.55.6|        | 10.50.55.9|       |10.50.55.12|
                 |           |        |           |       |           |
                 |           |        |           |       |           |
                 |           |        |           |       |           |
                 |           |        |           |       |           |
                 +------+----+        +----+------+       +-----+-----+
                        |                  |                    |
                        |                  |                    |
                        |                  |                    |
                        |                  |                    |
     management         |                  |                    |
           +------------+------------------+--------------------+---------------------+
```


### 1. Start with one master and two worker nodes, Ubuntu 18.04
You can use ansible - for some of the following tasks

### 2. Install upstream OVS on each host. Version 2.11.3-1
In this demo we used:
```
 # echo "deb http://3.19.28.122/openvswitch/stable /" |  tee /etc/apt/sources.list.d/openvswitch.list 
 # curl http://3.19.28.122/openvswitch/keyFile |  apt-key add - 
 # apt-get install libopenvswitch=2.11.3-1 openvswitch-common=2.11.3-1 openvswitch-switch=2.11.3-1 
 # systemctl restart openvswitch-switch.service
```
(See playbook install-ovs-upstream.yaml)

### 3. Install Kubernetes 1.16
(See install-stuff.yaml)

### 4. If you use a management network to access the test rig and a private network for k8s/ovn - make sure hostnames reflect the private network as well.
(see set-host-name.yaml)

### 5. create a k8s cluster, make sure to use the --skip-phases addon/kube-proxy flag.
In this demo we used: 
```
# kubeadm init --apiserver-advertise-address=10.50.55.6 --skip-phases addon/kube-proxy --pod-network-cidr 192.168.0.0/16 --service-cidr 10.90.0.0/16
```
(See playbook set-master.yaml)

### 6. join the worker node as usual
(see set-nodes.yaml)

### 7. Run the ovn-kubernetes daemonset and deployments.
The yaml files attached assume the topology drawn on the top of this README and the name of the device is enp175s0.
Note that we are using shared gateway, so the relevant yamls contain the gateway-interface and gateway-nexthop.
If you are using different addresses and device name you'll need to edit ovn-setup.yaml and ovnkube-node.yaml accordingly.
Also note that if you don't have a gateway/router in 10.50.55.1 - you can only test east-west traffic.
```
# kubectl create -f ovn-setup.yaml
# kubectl create -f ovnkube-db.yaml
# kubectl create -f ovnkube-master.yaml
# kubectl create -f ovnkube-node.yaml
```

### 8. Make sure you have SRIOV VFs on the worker node devices set to switchdev mode

### 9.  Run the sriov plugin
```
# kubectl create -f sriov-setup.yaml
# kubectl create -f sriovdp-daemonset.yaml
```

### 10. Deploy multus and set ovn as the default CNI
```
# kubectl create -f multus-daemonset.yaml
# kubectl create -f sriov-net.yaml
```

##3 11. Deploy a sample pod to verify sriov in the pod
```
# kubectl create -f gen-pod.yaml
# kubectl exec -it ub-pod -- ethtool -i eth0
```


Running tests/demos
TBD



