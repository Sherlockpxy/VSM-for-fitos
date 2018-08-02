#!/bin/bash

###################
# Add the ssh remote hosts
###################

#######################################
# Get the necessary configurations from the configuration file
#######################################
host_ip=$(cat configuration | grep ^controller_ip | cut -d = -f 2)
password=$(cat configuration | grep ^password | cut -d = -f 2)
ceph_num=$[$(cat configuration | grep ^name | wc -l)]
i=1
while [ $i -le $ceph_num ];do
    ceph_ip[i]=$(cat configuration | grep ^ip | cut -d = -f 2 | sed -n $i'p')
    i=$[$i+1]
done

############################
# Use ssh-copy-id to add the remote hosts
############################
./ssh_connect.exp $host_ip $password
j=1
while [ $j -le $ceph_num ];do
    ./ssh_connect.exp ${ceph_ip[j]} $password
    j=$[$j+1]
done

exit 0
