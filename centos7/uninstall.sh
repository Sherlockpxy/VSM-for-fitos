#!/bin/bash

# Copyright 2014 Intel Corporation, All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the"License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#  http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.


#!/bin/bash

TOPDIR=$(cd $(dirname "$0") && pwd)
USER=`whoami`

source $TOPDIR/installrc

#for ip in $CONTROLLER_ADDRESS; do
#    ssh -t $ip "sudo service vsm-api stop; sudo service vsm-scheduler stop; sudo service vsm-conductor stop; clean-data -f; yum -y erase ceph httpd MariaDB-client MariaDB-server memcached rabbitmq-server rbd-fuse vsm vsm-dashboard python-vsmclient vsm-deploy"
#done

#killall beam

#for ip in $AGENT_ADDRESS_LIST; do
#    ssh -t $ip "sudo service vsm-agent stop; sudo service vsm-physical stop; clean-data -f; yum -y erase ceph httpd librbd MariaDB-client MariaDB-devel MariaDB-server memcached openstack-keystone openstack-utils python-devel rabbitmq-server rbd-fuse vsm vsm-dashboard python-vsmclient vsm-deploy"
#done

for ip in $CONTROLLER_ADDRESS; do
    ssh -t $ip "sudo systemctl stop vsm-api"
    ssh -t $ip "sudo systemctl stop vsm-scheduler"
    ssh -t $ip "sudo systemctl stop vsm-conductor"
    ssh -t $ip "sudo systemctl restart mariadb"
    ssh -t $ip "sudo yum remove -y vsm vsm-dashboard python-vsmclient vsm-deploy"
    ssh -t $ip "sudo yum remove -y rabbitmq-server librabbitmq1 diamond"
    ssh -t $ip "sudo yum remove -y keystone python-keystone python-keystoneclient python-keystonemiddleware"
    ssh -t $ip "sudo killall rabbitmq-server beam beam.smp"
    ssh -t $ip "sudo rm -rf /var/lib/keystone /etc/keystone /etc/vsm /etc/vsm-dashboard /etc/vsmdeploy /var/lib/vsm /var/log/vsm"
done

for ip in $AGENT_ADDRESS_LIST; do
    ssh -t $ip "sudo systemctl stop vsm-agent"
    ssh -t $ip "sudo systemctl stop vsm-physical"
    ssh -t $ip "sudo yum remove -y vsm vsm-dashboard python-vsmclient vsm-deploy"
    ssh -t $ip "sudo yum remove -y diamond"
    ssh -t $ip "sudo yum remove -y python-keystoneclient"
    ssh -t $ip "sudo rm -rf /var/lib/vsm /var/log/vsm /etc/vsm"
done

