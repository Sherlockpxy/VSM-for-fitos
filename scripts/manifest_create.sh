#!/bin/bash

########################################
# Create manifest files named with controller's and agents' IPs
########################################

##########################
# Get the ips from the configuration file
##########################
host_ip=$(cat configuration | grep controller_ip | cut -d = -f 2)
ceph_cluster_name=$(cat configuration | grep ceph_cluster_name | cut -d = -f 2)
management_addr=$(cat configuration | grep management_addr | cut -d = -f 2)
ceph_public_addr=$(cat configuration | grep ceph_public_addr | cut -d = -f 2)
ceph_cluster_addr=$(cat configuration | grep ceph_cluster_addr | cut -d = -f 2)

ceph_num=$[$(cat configuration | grep ^'name=' | wc -l)]
i=1
while [ $i -le $ceph_num ];do
    ceph_ip[i]=$(cat configuration | grep ^'ip=' | cut -d = -f 2 | sed -n $i'p')
    ceph_role[i]=$(cat configuration | grep ^'role=' | cut -d = -f 2 | sed -n $i'p')
    dev=$(sed -n '/\[ceph'$i'\]/{h;:1;n;/^\s*$/!{H;b1};g;p;q}' configuration | grep '/dev' | cut -d = -f 2)
    device[i]=$(echo $dev | sed s/' '/'?'/g | sed s/','/' '/g)
    device_name[i]=$(sed -n '/\[ceph'$i'\]/{h;:1;n;/^\s*$/!{H;b1};g;p;q}' configuration | grep '/dev' | cut -d = -f 1)
    i=$[$i+1]
done
i=1
rules_number=$(cat configuration | grep 'storage_rules_number' | cut -d = -f 2)
rules=$(cat configuration | grep 'storage_rules=' | cut -d = -f 2)
while [ $i -le $rules_number ];do
    storage_rule[i]=$(echo $rules | cut -d , -f $i)
    i=$[$i+1]
done
#################
# Create cluster.manifest
#################
cd manifest
if [ ! $(ls $host_ip) ];then
    mkdir $host_ip
else
    echo $host_ip' exists'
fi
cd $host_ip
echo '[storage_class]' > cluster.manifest
i=1
while [ $i -le $rules_number ];do
echo ${storage_rule[i]} >> cluster.manifest
i=$[$i+1]
done

echo '
[storage_group]
#format: [storage group name]  [user friendly storage group name] [storage class]' >> cluster.manifest
j=1
while [ $j -le $rules_number ];do
echo ${storage_rule[j]}'  '${storage_rule[j]}'  '${storage_rule[j]} >> cluster.manifest
j=$[$j+1]
done

echo '
[cluster]
'$ceph_cluster_name'

[file_system]
xfs

[management_addr]
'$management_addr'

[ceph_public_addr]
'$ceph_public_addr'

[ceph_cluster_addr]
'$ceph_cluster_addr'

[settings]
storage_group_near_full_threshold  65
storage_group_full_threshold  85
ceph_near_full_threshold  75
ceph_full_threshold  90
pg_count_factor 100
heartbeat_interval 5
osd_heartbeat_interval 10
osd_heartbeat_grace 10

[ec_profiles]

[cache_tier_defaults]' >> cluster.manifest

cd ..

#################
# Create server.manifest
#################
i=1
while [ $i -le $ceph_num ];do
    mkdir ${ceph_ip[i]}
    cd ${ceph_ip[i]}
    echo -e '[vsm_controller_ip]
'$host_ip'

[role]
'${ceph_role[i]}'

[auth_key]
00000000000000000000000000000000000000000000000' > server.manifest

j=1
while [ $j -le $rules_number ];do
echo '
['${storage_rule[j]}']
#format [sas_device]  [journal_device]' >> server.manifest
k=$(echo ${device_name[j]} | sed s/' '/'\n'/g | wc -l)
for l in `seq $k`;do
disk=$(echo ${device_name[j]} | cut -d ' ' -f $l | sed s/[0-9]*//g)
if [[ ${storage_rule[j]} = $disk ]];then
    echo ${device[i]} | cut -d '?' -f $l >> server.manifest
fi
done
j=$[$j+1]
done
sed -i s/','/'\n'/g server.manifest
cd ..
i=$[$i+1]

done

exit 0
