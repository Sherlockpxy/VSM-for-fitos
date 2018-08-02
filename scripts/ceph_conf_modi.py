import re
import subprocess
import ConfigParser


#-------------------------------------------------------------
# This scipt is used on vsm-controller node to get the Ceph cluster's configurations
#-------------------------------------------------------------
config = ConfigParser.ConfigParser()
ceph_conf = ConfigParser.ConfigParser()
section = []
section_ceph = []
ceph_hostname = []
data = []
rules_data = []
rules_name = []
match_key_rule = []
osd_tree_data = []
storage_rules = {}
ceph_osd = {}
ceph_data = {}
ceph_journal = {}
ceph_ip = {}
ceph_public = {}
ceph_cluster = {}
mon_list = []

clear_rule = subprocess.Popen(["sed", "-i", "/rule/d", "configuration"], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
clear_dev = subprocess.Popen(["sed", "-i", "/'\/var\/lib\/ceph\/osd\/'/d", "configuration"], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

try:
    config.read('configuration')
except:
    print 'Read configurations error'

section = config.sections()
for i in section:
    if 'ceph' in i:
        section_ceph.append(i)
        ceph_hostname.append(config.get(i, 'name'))
        ceph_ip[config.get(i, 'name')]=config.get(i, 'ip')
        ceph_public[config.get(i, 'name')]=config.get(i, 'public_addr')
        ceph_cluster[config.get(i, 'name')]=config.get(i, 'cluster_addr')
        if 'monitor' in config.get(i, 'role').split(','):
            mon_list.append(config.get(i, 'name'))

# get the information from ceph nodes
for i in ceph_hostname:
    try:
        ssh = subprocess.Popen(["ssh", "root@%s" % i, "cat", "/proc/mounts", "|", "grep", "/var/lib/ceph/osd/"], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        data = ssh.stdout.readlines()
        if data == []:
            error = ssh.stderr.readlines()
            print "ERROR: %s" % error
    except:
        print 'Connection to remote Ceph servers failed'

    ceph_osd[i] = []
    ceph_data[i] = []
    ceph_journal[i] = []
    osd_num = 0

    # wirte down the informations of osds and disks for osds
    # there could be two situations:
    # 1. flashcache = 0
    # the result shall like:
    # ceph_osd = {'ceph01':['osd.0']}
    # ceph_data = {'ceph01':['/dev/sdb1']}
    # ceph_journal = {'ceph01':['/dev/sdb2']}
    # 2. flashcache = 1
    # the result shall like:
    # ceph_osd = {'ceph01':['osd.0']}
    # ceph_data = {'ceph01':['/dev/dm-1']}
    # ceph_journal = {'ceph01':['/dev/sdb2']}
    for j in data:
        osd_data = re.search(r'/dev/\S+', j).group()
        osd_journal = re.search(r'/var/lib/\S+', j).group()
        osd_num = re.search(r'\d+', osd_journal).group()
        osd_name = 'osd.' + osd_num
        ceph_osd[i].append(osd_name)
        ceph_data[i].append(osd_data)
        ceph_journal[i].append(osd_journal+'/journal')
        
# match host/osd/disk with storage group
try:
    rules = subprocess.Popen(["ssh", "root@%s" % ceph_hostname[0], "ceph", "osd", "crush", "rule", "list"], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    rules_data = rules.stdout.readlines()
    if rules_data == []:
        rules_error = rules_data.stderr.readlines()
        print "ERROR: %s" % rules.error
except:
    print 'Connection to remote Ceph server failed'
    # the storage rule's example
    # rules_name = ['replicated_ruleset', 'sas_rule', 'ssd_rule']
for i in rules_data:
    try:
        if re.search(r'\w*_\w*', i).group() == 'replicated_ruleset':
            rules_name.append('replicated_ruleset')
            match_key_rule.append('default')
        else:
            rules_name.append(re.search(r'\w*_\w*', i).group())
            # then we should match the osd with rule using 'ceph osd tree'
            # match_key_rule = ['default', 'sas', 'ssd']
            # the sequences are the same in rules_name and match_key_rule
            match_key_rule.append(re.search(r'[a-z,A-Z]*', re.search(r'\w*_\w*', i).group()).group())
    except:
        pass
# then deal with the message of  'ceph osd tree'
# this can help us konw the relationship of osd and storage rule
try:
    osd_tree = subprocess.Popen(["ssh", "root@%s" % ceph_hostname[0], "ceph", "osd", "tree"], shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    osd_tree_data = osd_tree.stdout.readlines()
    if osd_tree_data == []:
        osd_tree_error = osd_tree_data.stderr.readlines()
        print "ERROR: $s" % osd_tree_data
except:
    print 'Connection to remote Ceph server failed'
# the storage_rules shall be a dictionary just like this:
# {'sas_rule': ['osd.0', 'osd.2', 'osd.3', 'osd.4', 'osd.5', 'osd.13', 'osd.14', 
# 'osd.15', 'osd.16', 'osd.17', 'osd.7', 'osd.8', 'osd.9', 'osd.10', 'osd.11'], 
# 'replicated_ruleset': [], 'ssd_rule': ['osd.1', 'osd.12', 'osd.6']}
i = 0
rule_name = ""
while (i < len(osd_tree_data)):
    if "root" in osd_tree_data[i]:
        if "default" in osd_tree_data[i]:
            rule_name = "replicated_ruleset"
            storage_rules[rule_name] = []
        else:
            for j in range(0, len(match_key_rule)):
                if match_key_rule[j] in osd_tree_data[i]:
                    rule_name = rules_name[j]
            storage_rules[rule_name] = []
        i+=1
    elif "osd" in osd_tree_data[i]:
        storage_rules[rule_name].append(re.search(r'osd.\w*', osd_tree_data[i]).group())
        i+=1
    else:
        i+=1  
#-------------------------------------------------------------------------
# Edit the datas we get above
#-------------------------------------------------------------------------
# Fill the 'device' part of the configuration file 
device_name = ''
rules_into_config = ''
for i in range(0, len(section_ceph)):
    for j in range(0, len(ceph_osd[ceph_hostname[i]])):
        for k in storage_rules:
            if ceph_osd[ceph_hostname[i]][j] in storage_rules[k]:
                device_name = k
            else:
                pass
        config.set(section_ceph[i], device_name+'%s' % j, ceph_data[ceph_hostname[i]][j]+','+ceph_journal[ceph_hostname[i]][j])
config.set('global', 'storage_rules_number', len(rules_name))
for i in range(0, len(rules_name)):
    rules_into_config += rules_name[i] + ','
config.set('global', 'storage_rules', rules_into_config)
config.write(open('configuration', 'w'))

# create the ceph.conf file
# copy the origin ceph.conf file from the ceph servers
try:
    scp = subprocess.Popen(["scp", "root@%s:/etc/ceph/ceph.conf" % ceph_ip[ceph_hostname[0]], "."], shell=False)
    scp.wait()
except:
    print 'Scp ceph config files failed'
try:
    ceph_conf.read('ceph.conf')
except:
    print 'Read ceph.conf error'

# add the mon and osd information into ceph.conf
try:
    ceph_conf.add_section('mon')
except:
    print 'Section \'mon\' already exists'
ceph_conf.set('mon', 'mon_data', '/var/lib/ceph/mon/$cluster-$id')
ceph_conf.set('mon', 'mon_clock_drift_allowed', '0.05')

for i in mon_list:
    try:
        ceph_conf.add_section('mon.%s'%i)
    except:
        print 'Section mon'+ i+ ' already exists'
    ceph_conf.set('mon.%s'%i, 'host', i)
    ceph_conf.set('mon.%s'%i, 'mon_addr', '%s:6789'%ceph_public[i])

try:
    ceph_conf.add_section('osd')
except:
    print 'Section \'osd\' already exists'
ceph_conf.set('osd', 'osd_mount_options_xfs', 'rw,noatime,inode64,logbsize = 256k,delaylog')
ceph_conf.set('osd', '#osd_crush_update_on_start ', 'false')
ceph_conf.set('osd', '#filestore_xattr_use_omap', 'true')
ceph_conf.set('osd', 'keyring', '/var/lib/ceph/osd/ceph-$id/keyring')
ceph_conf.set('osd', 'osd_data', '/var/lib/ceph/osd/ceph-$id')
ceph_conf.set('osd', 'osd_heartbeat_grace', '10')
ceph_conf.set('osd', 'osd_heartbeat_interval', '10')
ceph_conf.set('osd', '#osd_mkfs_type', 'xfs')
ceph_conf.set('osd', '#osd_mkfs_options_xfs', '-f')

for i in ceph_hostname:
    for j in range(0, len(ceph_osd[i])):
        try:
            ceph_conf.add_section(ceph_osd[i][j])
        except:
            print 'Section '+ ceph_osd[i][j]+ ' already exists'
        ceph_conf.set(ceph_osd[i][j], 'osd_journal', ceph_journal[i][j])
        ceph_conf.set(ceph_osd[i][j], 'devs', ceph_data[i][j])
        ceph_conf.set(ceph_osd[i][j], 'host', i)
        ceph_conf.set(ceph_osd[i][j], 'cluster_addr', ceph_cluster[i])
        ceph_conf.set(ceph_osd[i][j], 'public_addr', ceph_public[i])

ceph_conf.write(open('ceph.conf', 'w'))

# delete the space(' ') nearby '='
try:
    modify = subprocess.Popen(["sed", "-i", "s/ //g", "configuration"], shell=False)
    print 'Ceph.conf has been gotten successfully!'
except:
    print 'Final modification failed!'
