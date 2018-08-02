#!/bin/bash
#################################
#Modify the ip and /etc/hosts configuration
#################################

#################################
# Get the given configuration of the controller host  
#################################
host_ip=$(cat configuration | grep ^controller_ip | cut -d = -f 2)
host_mask=$(cat configuration | grep ^controller_mask | cut -d = -f 2)
host_gateway=$(cat configuration | grep ^controller_gateway | cut -d = -f 2)
host_adapter=$(cat configuration | grep ^controller_management_network_adapter | cut -d = -f 2)
host_public_adapter=$(cat configuration | grep ^controller_public_adapter | cut -d = -f 2)
host_public_addr=$(cat configuration | grep ^controller_public_addr | cut -d = -f 2)
host_public_mask=$(cat configuration | grep ^controller_public_mask | cut -d = -f 2)
# Determine if the configuration information is missing
#if [[ $host_ip && $host_mask && $host_gateway && $host_adapter ]];then
#    :
#else
#    echo 'There must be some configuraions lost, please check the configuration
#          file about controller ip, mask, gateway and network adapter.'
#    exit 0
#fi

#############################
# Modify the ip configuration of the controller
#############################
# Modify the vsm management ip
#ip_conf_path='/etc/sysconfig/network-scripts/ifcfg-'$host_adapter
#ip_addr=$(cat $ip_conf_path | grep ^IPADDR)
#ip_mask=$(cat $ip_conf_path | grep ^NETMASK)
#ip_gateway=$(cat $ip_conf_path | grep ^GATEWAY)
#
#sed -i /^BOOTPROTO/s/dhcp/static/g $ip_conf_path
#if [ $ip_addr ];then
#    sed -i /^IPADDR/s/.*/'IPADDR='$host_ip/g $ip_conf_path
#else
#    sed -i '$a IPADDR='$host_ip $ip_conf_path
#fi
#if [ $ip_mask ];then
#    sed -i /^NETMASK/s/.*/'NETMASK='$host_mask/g $ip_conf_path
#else
#    sed -i '$a NETMASK='$host_mask $ip_conf_path
#fi
#if [ $ip_gateway ];then
#    sed -i /^GATEWAY/s/.*/'GATEWAY='$host_gateway/g $ip_conf_path
#else
#    sed -i '$a GATEWAY='$host_gateway $ip_conf_path
#fi
## Modify the ceph public network ip
#ip_conf_path='/etc/sysconfig/network-scripts/ifcfg-'$host_public_adapter
#ip_public_addr=$(cat $ip_conf_path | grep ^IPADDR)
#ip_public_mask=$(cat $ip_conf_path | grep ^NETMASK)
#ip_public_gateway=$(cat $ip_conf_path | grep ^GATEWAY)
#
#sed -i /^BOOTPROTO/s/dhcp/static/g $ip_conf_path
#if [ $ip_public_addr ];then
#    sed -i /^IPADDR/s/.*/'IPADDR='$host_public_addr/g $ip_conf_path
#else
#    sed -i '$a IPADDR='$host_public_addr $ip_conf_path
#fi
#if [ $ip_public_mask ];then
#    sed -i /^NETMASK/s/.*/'NETMASK='$host_public_mask/g $ip_conf_path
#else
#    sed -i '$a NETMASK='$host_public_mask $ip_conf_path
#fi
#if [ $ip_public_gateway ];then
#    sed -i /^GATEWAY/s/.*/'GATEWAY='$host_public_gateway/g $ip_conf_path
#else
#    sed -i '$a GATEWAY='$host_public_gateway $ip_conf_path
#fi

##################
# Modify the /etc/hosts file
##################
# get ceph clusters' ip information from the configuration file
ceph_num=$[$(cat configuration | grep ^'name=' | wc -l)]
i=1

if [ $ceph_num -le 0 ];then
    echo 'Cannot get the configuration of ceph cluster (at least one node), 
          please check the configuration file'
    exit 0
else
    while [ $i -le $ceph_num ];do
        ceph_name[i]=$(cat configuration | grep ^'name=' | cut -d = -f 2 | sed -n $i'p')
        ceph_ip[i]=$(cat configuration | grep ^'ip=' | cut -d = -f 2 | sed -n $i'p')
        ceph_public_ip[i]=$(cat configuration | grep ^'public_addr=' | cut -d = -f 2 | sed -n $i'p')
        ceph_cluster_ip[i]=$(cat configuration | grep ^'cluster_addr=' | cut -d = -f 2 | sed -n $i'p')
        i=$[$i+1]
    done
fi

# Modify the hosts
hosts_path='/root/hosts'
# Clear the old configuraions of vsm-controller and ceph nodes
#j=1
#sed -i /vsm-controller/d $hosts_path
#while [ $j -le $ceph_num ];do
#    sed -i /${ceph_name[j]}/d $hosts_path
#    j=$[$j+1]
#done

j=1
echo $host_ip' vsm-controller' > $hosts_path
while [ $j -le $ceph_num ];do
    echo ${ceph_ip[j]}' '${ceph_name[j]} >> $hosts_path
    j=$[$j+1]
done
sed -i '$a \ ' $hosts_path

j=1
echo $host_public_addr' vsm-controller' >> $hosts_path
while [ $j -le $ceph_num ];do
    echo ${ceph_public_ip[j]}' '${ceph_name[j]} >> $hosts_path
    j=$[$j+1]
done
sed -i '$a \ ' $hosts_path

j=1
while [ $j -le $ceph_num ];do
    echo ${ceph_cluster_ip[j]}' '${ceph_name[j]} >> $hosts_path
    j=$[$j+1]
done

echo '''127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
''' > /etc/hosts

cat /root/hosts >> /etc/hosts

####################
# Restart the network service
####################
#ifdown $host_adapter
#ifdown $host_public_adapter
#ifup $host_adapter
#ifup $host_public_adapter

####################
# Create pip.conf file
####################
echo '[global]
index-url=http://'$host_ip'/opt/pypi/simple/
[install]
trusted-host='$host_ip > pip.conf

####################
# Modify the httpd.conf and wsgi-keystone.conf
####################
##path_http='/root/test.py'
path_httpd='/etc/httpd/conf/httpd.conf'
path_keystone='/usr/share/keystone/wsgi-keystone.conf'
ip=$(sed -r "s/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\n\1/;s/^.*\n//" $path_keystone | head -1)
sed -i s/$ip/$host_ip/g $path_httpd
sed -i s/$ip/$host_ip/g $path_keystone
systemctl restart httpd

exit 0
