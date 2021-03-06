
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

from django.utils.translation import ugettext_lazy as _

import horizon

class Dashboard(horizon.PanelGroup):
    slug = 'dashboard'
    name = _("Dashboard")
    panels = ('overview',)

#class ClusterMgmt(horizon.PanelGroup):
#    slug = "clustermgmt"
#    name = _("Cluster Management")
#    panels = ('clustermgmt', 'cluster-import', 'cephupgrade', 'poolsmanagement','ecprofiles-management','crushmap','zonemgmt')

class ClusterMgmt(horizon.PanelGroup):
    slug = "clustermgmt"
    name = _("Cluster Management")
    panels = ('cluster-import',)

#class ClusterMonitor(horizon.PanelGroup):
#    slug = "clustermonitor"
#    name = _("Cluster Monitoring")
#    panels = ('storage-group-status', 'pool-status', 'osd-status', 'monitor-status', \
#              'mds-status', 'pg-status', 'rbd-status')

class ClusterMonitor(horizon.PanelGroup):
    slug = "clustermonitor"
    name = _("Cluster Monitoring")
    panels = ('storage-group-status', 'pool-status', 'osd-status', 'monitor-status', \
              'pg-status', 'rbd-status')

class ServerMgmt(horizon.PanelGroup):
    slug = "servermgmt"
    name = _("Server Management")
    panels = ('storageservermgmt', 'devices-management',)

#class OpenstackMgmt(horizon.PanelGroup):
#    slug = "openstackmgmt"
#    name = _("OpenStack Integration")
#    panels = ('rbdpools', 'openstackconnect',)

class OpenstackMgmt(horizon.PanelGroup):
    slug = "openstackmgmt"
    name = _("OpenStack Integration")
    panels = ()

class UserMgmt(horizon.PanelGroup):
    slug = "usermgmt"
    name = _("VSM Management")
    panels = ("usermgmt", 'settings')

class VizDash(horizon.Dashboard):
    name = _("VSM")
    slug = "vsm"
    panels = (Dashboard, ServerMgmt, ClusterMgmt, ClusterMonitor, OpenstackMgmt, UserMgmt)
    default_panel = 'overview'
    roles = ('admin',)

horizon.register(VizDash)
