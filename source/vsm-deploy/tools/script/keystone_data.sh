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

set -e
set -o xtrace

export OS_USERNAME=""
export OS_AUTH_KEY=""
export OS_AUTH_TENANT=""
export OS_STRATEGY=""
export OS_AUTH_STRATEGY=""
export OS_AUTH_URL=""
export SERVICE_ENDPOINT=""

export SERVICE_TOKEN=%SERVICE_TOKEN%
export ADMIN_PASSWORD=%ADMIN_PASSWORD%
export SERVICE_TENANT_NAME=%SERVICE_TENANT_NAME%
export KEYSTONE_HOST=%KEYSTONE_HOST%
export SERVICE_ENDPOINT=%SERVICE_ENDPOINT%
export KEYSTONE_CATALOG_BACKEND=%KEYSTONE_CATALOG_BACKEND%
export AGENT_PASSWORD=%AGENT_PASSWORD%
export OS_TENANT_NAME=%ADMIN_USER%
export OS_USERNAME=%ADMIN_USER%
export OS_PASSWORD=%ADMIN_PASSWORD%
export OS_AUTH_URL=http://%KEYSTONE_HOST%:5000/v2.0/

keyrc=~/keyrc

# Tenants
# -------

ADMIN_TENANT=$(openstack project create admin --or-show -f value -c id)
echo "export ADMIN_TENANT=$ADMIN_TENANT" >> $keyrc

SERVICE_TENANT=$(openstack project create $SERVICE_TENANT_NAME --or-show -f value -c id)
echo "export SERVICE_TENANT=$SERVICE_TENANT" >> $keyrc

DEMO_TENANT=$(openstack project create demo --or-show -f value -c id)
echo "export DEMO_TENANT=$DEMO_TENANT" >> $keyrc

AGENT_TENANT=$(openstack project create agent --or-show -f value -c id)
echo "export AGENT_TENANT=$AGENT_TENANT" >> $keyrc

INVIS_TENANT=$(openstack project create invisible_to_admin --or-show -f value -c id)

# Users
# -----

ADMIN_USER=$(openstack user create --password="$ADMIN_PASSWORD" \
                                   --email=admin@intel.com admin \
                                   --or-show -f value -c id)
DEMO_USER=$(openstack user create --password="$ADMIN_PASSWORD" \
                                   --email=demo@intel.com demo \
                                   --or-show -f value -c id)
AGENT_USER=$(openstack user create --password="$AGENT_PASSWORD" \
                                   --email=agent@intel.com agent \
                                   --or-show -f value -c id)

# Roles
# -----

ADMIN_ROLE=$(openstack role create admin --or-show -f value -c id)
echo "export ADMIN_ROLE=$ADMIN_ROLE" >> $keyrc

AGENT_ROLE=$(openstack role create agent --or-show -f value -c id)
echo "export AGENT_ROLE=$AGENT_ROLE" >> $keyrc

KEYSTONEADMIN_ROLE=$(openstack role create KeystoneAdmin --or-show -f value -c id)
echo "export KEYSTONEADMIN_ROLE=$KEYSTONEADMIN_ROLE" >> $keyrc

KEYSTONESERVICE_ROLE=$(openstack role create KeystoneServiceAdmin --or-show -f value -c id)
# ANOTHER_ROLE demonstrates that an arbitrary role may be created and used
# TODO(sleepsonthefloor): show how this can be used for rbac in the future!
ANOTHER_ROLE=$(openstack role create anotherrole --or-show -f value -c id)

# Add Roles to Users in Tenants
# keystone user-role-add --user_id $ADMIN_USER --role_id $ADMIN_ROLE --tenant_id $ADMIN_TENANT
# keystone user-role-add --user_id $ADMIN_USER --role_id $ADMIN_ROLE --tenant_id $DEMO_TENANT
# keystone user-role-add --user_id $DEMO_USER --role_id $ANOTHER_ROLE --tenant_id $DEMO_TENANT
# keystone user-role-add --user_id $AGENT_USER --role_id $AGENT_ROLE --tenant_id $AGENT_TENANT
#openstack role add --user $ADMIN_USER --project $ADMIN_TENANT $ADMIN_ROLE
openstack role add --user $ADMIN_USER --project $DEMO_TENANT $ADMIN_ROLE
openstack role add --user $DEMO_USER --project $DEMO_TENANT $ANOTHER_ROLE
openstack role add --user $AGENT_USER --project $AGENT_TENANT $AGENT_ROLE


# TODO(termie): these two might be dubious
# keystone user-role-add --user_id $ADMIN_USER --role_id $KEYSTONEADMIN_ROLE --tenant_id $ADMIN_TENANT
# keystone user-role-add --user_id $ADMIN_USER --role_id $KEYSTONESERVICE_ROLE --tenant_id $ADMIN_TENANT
openstack role add --user $ADMIN_USER --project $ADMIN_TENANT $KEYSTONEADMIN_ROLE
openstack role add --user $ADMIN_USER --project $ADMIN_TENANT $KEYSTONESERVICE_ROLE

# The Member role is used by Horizon and Swift so we need to keep it:
MEMBER_ROLE=$(openstack role create Member --or-show -f value -c id)
# keystone user-role-add --user_id $DEMO_USER --role_id $MEMBER_ROLE --tenant_id $DEMO_TENANT
# keystone user-role-add --user_id $DEMO_USER --role_id $MEMBER_ROLE --tenant_id $INVIS_TENANT
openstack role add --user $DEMO_USER --project $DEMO_TENANT $MEMBER_ROLE
openstack role add --user $DEMO_USER --project $INVIS_TENANT $MEMBER_ROLE

# Services
# --------

# KEYSTONE_SERVICE=$(get_id keystone service-create \
#  	--name=keystone \
# 	--type=identity \
#  	--description="Keystone Identity Service")  
#KEYSTONE_SERVICE=$(openstack service create \
#                   --name=keystone \
#                   --description="Keystone Identity Service" \
#                   identity -f value -c id)

# keystone endpoint-create \
#      --region RegionOne \
#  	--service_id $KEYSTONE_SERVICE \
#	--publicurl "http://$KEYSTONE_HOST:\$(public_port)s/v2.0" \
#	--adminurl "http://$KEYSTONE_HOST:\$(admin_port)s/v2.0" \
#	--internalurl "http://$KEYSTONE_HOST:\$(admin_port)s/v2.0"

# openstack endpoint create \
#    --region RegionOne \
#	--publicurl "http://$KEYSTONE_HOST:\$(public_port)s/v2.0" \
#	--adminurl "http://$KEYSTONE_HOST:\$(admin_port)s/v2.0" \
#	--internalurl "http://$KEYSTONE_HOST:\$(admin_port)s/v2.0" \
#    $KEYSTONE_SERVICE

set +o xtrace
