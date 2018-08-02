#!/bin/bash

################################
# Add controller and agent ip to the file installrc.py
################################

#######################################
# Get the necessary configurations from the configuration file
#######################################
host_ip=$(cat configuration | grep controller_ip | cut -d = -f 2)
ceph_num=$[$(cat configuration | grep ^'name=' | wc -l)]
i=1
while [ $i -le $ceph_num ];do
    ceph_ip[i]=$(cat configuration | grep ^'ip=' | cut -d = -f 2 | sed -n $i'p')
    i=$[$i+1]
done

#################
#Modify the installrc file
#################
# Add or overwrite
installrc_path='installrc'
controller_addr=$(cat $installrc_path | grep ^CONTROLLER_ADDRESS)
agent_addr=$(cat $installrc_path | grep ^AGENT_ADDRESS_LIST | sed 's/ /,/g')

# Add the controller info
if [ $controller_addr ];then
    sed -i /^CONTROLLER_ADDRESS/s/.*/'CONTROLLER_ADDRESS="'$host_ip'"'/g $installrc_path
else
    sed -i '$a CONTROLLER_ADDRESS="'$host_ip'"' $installrc_path
fi

# Add the agents' info
message='"'
for j in ${ceph_ip[@]};do
    message=$message$j','
done
message=$message'"'

if [ $agent_addr ];then
    sed -i /^AGENT_ADDRESS_LIST/s/.*/'AGENT_ADDRESS_LIST='$message/g $installrc_path
else
    sed -i '$a AGENT_ADDRESS_LIST='$message $installrc_path
fi
sed -i '/AGENT_ADDRESS_LIST/s/,/ /g' $installrc_path

exit 0
