vagrant-docker-oracle12c
========================

[Japanese version here](README_ja.md)

Vagrant + Docker + Oralce Linux 6.5 + Oracle Database 12cR1 (12.1.0.2 Enteprise Edition) setup.
Does not include the DB12c binary.
You need to download that from the official site beforehand.

as of 7/26/2014 (updated for 12.1.0.2)

## Setup

* Host
  * Oracle Linux 6.5 (converted from CentOS6.5)
  * oracle-rdbms-server-12cR1-preinstall
  * Docker
  * Unbreakable Enterprise Kernel
* Container
  * Oracle Linux 6.5 (converted from CentOS6.5)
  * oracle-rdbms-server-12cR1-preinstall
  * Oracle Datbabase 12cR1

```
      Oracle Database 12cR1 (EE)          <- manual setup
---------------------------------------
      Oracle Linux 6.5 (Container)        <- uses Docker
---------------------------------------
                Docker                    <- uses Vagrant
---------------------------------------
         Oracle Linux 6.5 (Host)          <- uses Vagrant
---------------------------------------
              VirtualBox
---------------------------------------
                MacOSX
```

## Download

Download the database binary (12.1.0.2.0) from below.  Unzip to the subdirectory name "database".

http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

* linuxamd64_12c_database_1of2.zip
* linuxamd64_12c_database_2of2.zip

## Vagrant Setup

If you are behing a proxy, install vagrant-proxyconf.
```
(MacOSX)
$ export http_proxy=proxy:port
$ export https_proxy=proty:port

(Windows)
$ set http_proxy=proxy:port
$ set https_proxy=proxy:port

$ vagrant plugin install vagrant-proxyconf
```

Install VirtualBox plugin.
```
$ vagrant plugin install vagrant-vbguest
```

Clone this repository to the local directory.  Move the "database" directory to the same folder.
```
$ git clone https://github.com/yasushiyy/vagrant-docker-oracle12c
$ cd vagrant-docker-oracle12c
 ```

If you are behind a proxy, add follwing to Vagrantfile:
```
config.proxy.http     = "http://proxy:port"
config.proxy.https    = "http://proxy:port"
config.proxy.no_proxy = "localhost,127.0.0.1"
```

## Host OS Install (Vagrant)

vagrant up will do the following:
* download CentOS 6.5 and boot up
* convert into Oracle Linux 6.5 https://linux.oracle.com/switch/centos/
* fix locale warning
* install oracle-rdbms-server-12cR1-preinstall
* install docker-io, update to the latest binary
* install UEKR3 and make it a default kernel

```
$ vagrant up
   :
==> default: Oracle Linux Server release 6.5
```

Reboot to switch the kernel to UEKR3.  Confirm that NUMA and Transparent Hugepage is turned "off".
```
$ vagrant reload

$ vagrant ssh

[vagrant@localhost ~]$ dmesg | more
Initializing cgroup subsys cpuset
Initializing cgroup subsys cpu
Linux version 3.8.13-35.3.2.el6uek.x86_64 (mockbuild@ca-build44.us.oracle.com) (gcc version 4.4.7 20120313 (Red Hat 4.4.7-3) (GCC) ) #2 SMP Tue Jul 22 13:17:34 PDT 2014
Command line: ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 rd_LVM_LV=VolGroup/lv_root  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet numa=off transparent_hugepage=never
   :

[vagrant@localhost ~]$ exit

```

## Container OS Install (Docker)

Pull the Oracle Linux 6.5 Docker image from the Docker Hub repository.

Image was created in the following way:
* use official centos:centos6 image
* convert into Oracle Linux 6.5 https://linux.oracle.com/switch/centos/
* fix missing MAKEDEV error
* fix locale warning
* install vim
* install oracle-rdbms-server-12cR1-preinstall
* create install directories
* add ORACLE_XX environment variables

```
$ vagrant ssh

[vagrant@localhost ~]$ sudo docker pull yasushiyy/vagrant-docker-oracle12c
```

## DB Install

Connect to the container.
```
[vagrant@localhost ~]$ sudo docker run --privileged -h db12c -p 11521:1521 -t -i -v /vagrant:/vagrant yasushiyy/vagrant-docker-oracle12c /bin/bash
```

Install Database.
```
bash-4.1# su - oracle

[oracle@db12c ~]$ /vagrant/database/runInstaller -silent -showProgress -ignorePrereq -responseFile /vagrant/db_install.rsp
Starting Oracle Universal Installer…
  :
[WARNING] - My Oracle Support Username/Email Address Not Specified
[SEVERE] - The product will be registered anonymously using the specified email address.
  :
Setup Oracle Base successful.
..................................................   95% Done.

As a root user, execute the following script(s):
	1. /opt/oraInventory/orainstRoot.sh
	2. /opt/oracle/product/12.1.0.2/dbhome_1/root.sh



..................................................   100% Done.
Successfully Setup Software.

[oracle@db12c ~]$ exit

bash-4.1# /opt/oraInventory/orainstRoot.sh
Changing permissions of /opt/oraInventory.
Adding read,write permissions for group.
Removing read,write,execute permissions for world.

Changing groupname of /opt/oraInventory to oinstall.
The execution of the script is complete.

bash-4.1# /opt/oracle/product/12.1.0.2/dbhome_1/root.sh
Check /opt/oracle/product/12.1.0.2/dbhome_1/install/root_db12c_2014-07-26_02-54-11.log for the output of root script
```

Create listener using netca.
```
bash-4.1# su - oracle

[oracle@db12c ~]$ netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp

Parsing command line arguments:
    Parameter "silent" = true
    Parameter "responsefile" = /opt/oracle/product/12.1.0.2/dbhome_1/assistants/netca/netca.rsp
Done parsing command line arguments.
Oracle Net Services Configuration:
Profile configuration complete.
Oracle Net Listener Startup:
    Running Listener Control:
      /opt/oracle/product/12.1.0.2/dbhome_1/bin/lsnrctl start LISTENER
    Listener Control complete.
    Listener started successfully.
Listener configuration complete.
Oracle Net Services configuration successful. The exit code is 0
```

Create Database.
```
[oracle@db12c ~]$ dbca -silent -createDatabase -responseFile /vagrant/dbca.rsp
Copying database files
1% complete
3% complete
11% complete
18% complete
37% complete
Creating and starting Oracle instance
40% complete
45% complete
50% complete
55% complete
56% complete
60% complete
62% complete
Completing Database Creation
66% complete
70% complete
73% complete
85% complete
96% complete
100% complete
Look at the log file "/opt/oracle/cfgtoollogs/dbca/orcl/orcl.log" for further details.
```

Test connection.
```
[oracle@db12c ~]$ sqlplus system/oracle@localhost:1521/orcl

SQL*Plus: Release 12.1.0.2.0 Production on Sat Jul 26 03:03:32 2014

Copyright (c) 1982, 2014, Oracle.  All rights reserved.


Connected to:
Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options

SQL> select * from dual;

D
-
X

SQL> select count(1) from user_tables;

  COUNT(1)
----------
       178

SQL> show parameter inmemory

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
inmemory_clause_default 	     string
inmemory_force			     string	 DEFAULT
inmemory_max_populate_servers	     integer	 0
inmemory_query			     string	 ENABLE
inmemory_size			     big integer 0
inmemory_trickle_repopulate_servers_ integer	 1
percent
optimizer_inmemory_aware	     boolean	 TRUE

SQL> exit
Disconnected from Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options
```
