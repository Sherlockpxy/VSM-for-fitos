VSM - Virtual Storage Manager 
=============================
![](https://github.com/01org/virtual-storage-manager/blob/master/vsm_0.jpg "Virtual Storage Manager")

Virtual Storage Manager (VSM) is software that Intel has developed to help manage Ceph clusters.  VSM simplifies 
the creation and day-to-day management of Ceph cluster for cloud and datacenter storage administrators. 

VSM enables OEMs and system integrators to ensure consistent cluster configuration through the use of pre-defined,
standard cluster configurations, and as a result improves ease of cluster installation and operational reliability,
and reduces maintenance and support costs.

VSM supports the creation of clusters containing a mix of hard disk drives (HDDs), Solid State storage, and SSD-cached
HDDs, and simplifies management of the Ceph cluster using a system to organize servers and storage devices according
to performance characteristics, intended use, and failure domain.

The VSM web-based user interface provides the operator with the ability to monitor overall cluster status, manage
cluster hardware and storage capacity, inspect detailed operation status of Ceph subsystems, and attach Ceph pools
to OpenStack Cinder.

VSM has been developed in Python using OpenStack Horizon as the starting point for the application framework, and 
has a familiar look and feel for both software developers and OpenStack administrators. 


Personal Changes
---------
This is a secondary programming result of Intel VSM. In order to fit for new centos version and Fiberhome fitos platform, the code has been modified for serverl times as below:

a) Modify the source code to make it useful in CentOS 7.2 and CentOS 7.4.

b) Change some dependency packages' version or format.

c) Add several shell and python scripts for installation.

d) Modify some fuctions, e.g. support flashcache.
