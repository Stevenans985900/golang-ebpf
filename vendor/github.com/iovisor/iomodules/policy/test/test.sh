#!/bin/bash

sudo ip netns add host1
sudo ip netns add host2

sudo ip netns exec host1 sudo ip link  set lo up
sudo ip netns exec host2 sudo ip link  set lo up

sudo ip link add br0 type bridge
sudo ip link set br0 up

sudo ip link add veth1 type veth peer name eth0
sudo ip link set  eth0 netns host1

sudo ip link add veth2 type veth peer name eth0
sudo ip link set eth0 netns host2

sudo ip netns exec host1 ip link add br0 type bridge
sudo ip netns exec host2 ip link add br0 type bridge

sudo ip netns exec host1 ip link add br1 type bridge
sudo ip netns exec host2 ip link add br1 type bridge

sudo ip netns exec host1 ip link add vxlan1 type vxlan vni 1234 group 239.1.1.1 dstport 4789 dev br1
sudo ip netns exec host1 ip link set vxlan1 up

sudo ip netns exec host2 ip link add vxlan1 type vxlan vni 1234 group 239.1.1.1 dstport 4789 dev br1
sudo ip netns exec host2 ip link set vxlan1 up


sudo ip netns exec host1 ip link set dev eth0 master br1
sudo ip netns exec host2 ip link set dev eth0 master br1

sudo ip netns exec host1 ip addr add 192.168.1.1/24 dev br1
sudo ip netns exec host2 ip addr add 192.168.1.2/24 dev br1

sudo ip netns add cont1
sudo ip netns add cont2

sudo ip netns exec host1 ip link add h-veth1 type veth peer name c-eth1
sudo ip netns exec host1 ip link set c-eth1 netns cont1

sudo ip link set dev veth1 master br0
sudo ip link set dev veth2 master br0

sudo ip netns exec host2 ip link add h-veth1 type veth peer name c-eth1
sudo ip netns exec host2 ip link set c-eth1 netns cont2

sudo ip netns exec host1 ip link set dev h-veth1 master br0
sudo ip netns exec host2 ip link set dev h-veth1 master br0

sudo ip netns exec host1 ip link set dev vxlan1 master br0
sudo ip netns exec host2 ip link set dev vxlan1 master br0

sudo ip netns exec cont1 ip addr add 10.1.1.1/24 dev c-eth1
sudo ip netns exec cont2 ip addr add 10.1.1.2/24 dev c-eth1

sudo ifconfig veth1 up
sudo ifconfig veth2 up

sudo ip netns exec host1 ifconfig br1 up
sudo ip netns exec host2 ifconfig br1 up

sudo ip netns exec host1 ifconfig eth0 up
sudo ip netns exec host2 ifconfig eth0 up
sudo ip netns exec host1 ifconfig br0 up
sudo ip netns exec host1 ifconfig h-veth1 up
sudo ip netns exec host2 ifconfig h-veth1 up
sudo ip netns exec host2 ifconfig br0 up
sudo ip netns exec cont1 ifconfig c-eth1 up
sudo ip netns exec cont2 ifconfig c-eth1 up

sudo ip netns exec host1 $GOPATH/bin/hoverd &
sudo ip netns exec host2 $GOPATH/bin/hoverd &

sleep 5

sudo ip netns exec host1 $GOPATH/bin/policy -dataplane http://localhost:5000 &
sudo ip netns exec host2 $GOPATH/bin/policy -dataplane http://localhost:5000 &

sleep 5

sudo ip netns exec host1 $GOPATH/bin/policy-ctl endpoint-group create --endpoint-group-name web --wire-id 100
sudo ip netns exec host1 $GOPATH/bin/policy-ctl endpoint-group create --endpoint-group-name app --wire-id 200
sudo ip netns exec host1 $GOPATH/bin/policy-ctl endpoint create --endpoint-group-name web --ipaddress 10.1.1.1
sudo ip netns exec host1 $GOPATH/bin/policy-ctl endpoint create --endpoint-group-name app --ipaddress 10.1.1.2

sudo ip netns exec host2 $GOPATH/bin/policy-ctl endpoint-group create --endpoint-group-name web --wire-id 100
sudo ip netns exec host2 $GOPATH/bin/policy-ctl endpoint-group create --endpoint-group-name app --wire-id 200
sudo ip netns exec host2 $GOPATH/bin/policy-ctl endpoint create --endpoint-group-name web --ipaddress 10.1.1.1
sudo ip netns exec host2 $GOPATH/bin/policy-ctl endpoint create --endpoint-group-name app --ipaddress 10.1.1.2

sudo ip netns exec host1 $GOPATH/bin/policy-ctl policy-rule create --source-endpoint-group web --dest-endpoint-group app --protocol 1
sudo ip netns exec host1 $GOPATH/bin/policy-ctl policy-rule create --source-endpoint-group app --dest-endpoint-group web --protocol 1

sudo ip netns exec host2 $GOPATH/bin/policy-ctl policy-rule create --source-endpoint-group web --dest-endpoint-group app --protocol 1
sudo ip netns exec host2 $GOPATH/bin/policy-ctl policy-rule create --source-endpoint-group app --dest-endpoint-group web --protocol 1
