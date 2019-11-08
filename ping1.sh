#!/bin/bash

NODE2=`kubectl get nodes | grep -v master | head -n 2 | tail -n 1 | awk '{print $1}'`
NODE3=`kubectl get nodes | grep -v master | head -n 3 | tail -n 1 | awk '{print $1}'`
kubectl label nodes $NODE2 nodeName=node2 --overwrite
kubectl label nodes $NODE3 nodeName=node3 --overwrite

set -e
set -u

TEST=`basename $0`
D=`dirname $0`

echo "ping 1"

set +e
#blocking
kubectl delete -f $D/ping1.yaml 2>/dev/null
set -e

kubectl -v=6 create -f $D/ping1.yaml

kubectl wait pod --for=condition=Ready -l k8s-app=ping1-test --timeout=30s || (echo "ERROR starting ping1-test pods" ; exit 1)

for N in node2-pod node3-pod ; do

	kubectl exec -it $N -- ethtool -i eth0 | grep -q mlx5 
	if [ $? -ne 0 ] ; then
		echo -e "\nCan't find mlnx in $N\n" && kubectl delete -f $D/iperf1.yaml 2>/dev/null && exit
	fi

done

echo "ping east-west"
IP_NODE2=$(kubectl get pod node2-pod --template={{.status.podIP}})
kubectl exec -it node3-pod -- ping -W 2 -c 10 $IP_NODE2
RV=$?
if [ $RV -ne 0 ] ; then
	echo "ERROR $TEST"
	exit 1
fi

echo "Passed $TEST"

set +e
kubectl delete -f $D/ping1.yaml 2>/dev/null
set -e


