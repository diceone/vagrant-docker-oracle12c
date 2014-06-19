vagrant-docker-oracle12c
========================

Vagrant + Docker + Oralce Linux 6.5 + Oracle Database 12cR1 (Enteprise Edition) setup.  Does not include the DB12c binary.  You need to download that from the official site beforehand.

as of 6/15/2014

## Setup

* Host
  * Oracle Linux 6.5 (converted from CentOS6.5)
  * oracle-rdbms-server-12cR1-preinstall
  * Docker
  * Unbreakable Enterprise Kernel
* Container https://registry.hub.docker.com/u/yasushiyy/oraclelinux6/ 
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

## Prepare

Clone this repository to the local directory.
* Vagrantfile: uses CentOS 6.5, memory=2048M, reads setup.sh
* setup.sh: converts into Oracle Linux, installs necessary packages
* db12c.rsp: response file for DB silent install

```
$ git clone https://github.com/yasushiyy/vagrant-docker-oracle12c
$ cd vagrant-docker-oracle12c
 ```

If you are behind a proxy, edit setup.sh to add "export HTTPS_PROXY=<proxy:port>".

Download the database binary form below.  Unzip to the same directory as above.  It should have the subdirectory name "database".

http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

* linuxamd64_12c_database_1of2.zip
* linuxamd64_12c_database_2of2.zip

Install VirtualBox plugin.

```
$ vagrant plugin install vagrant-vbguest
```

## Install Host OS

vagrant up will do the following:
* download CentOS 6.5 and boot up
* convert into Oracle Linux 6.5 https://linux.oracle.com/switch/centos/
* fix locale warning
* install oracle-rdbms-server-12cR1-preinstall
* install lxc-docker
* install UEK and make it a default kernel
  * does not use UEKR3 at this point

```
$ vagrant up
   :
==> default: Oracle Linux Server release 6.5
```

Reboot to switch the kernel to UEKR2.  Confirm that NUMA and Transparent Hugepage is turned "off".

```
$ vagrant reload

$ vagrant ssh
Last login: Thu Jun 12 12:28:48 2014 from 10.0.2.2

[vagrant@localhost ~]$ dmesg | more
Initializing cgroup subsys cpuset
Initializing cgroup subsys cpu
Linux version 2.6.39-400.215.2.el6uek.x86_64 (mockbuild@ca-build44.us.oracle.com
) (gcc version 4.4.6 20110731 (Red Hat 4.4.6-3) (GCC) ) #1 SMP Fri Jun 6 12:51:4
4 PDT 2014
Command line: ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS LANG=en_US.UTF-8 r
d_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 rd_LVM_LV=VolGroup/
lv_root  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet numa=off transparent_hu
gepage=never
   :

[vagrant@localhost ~]$ exit 

```

## Install Container OS

As of writing, EPEL repository's lxc-docker is a bit old.  It should be updated very soon.

```
$ vagrant ssh

[vagrant@localhost ~]$ sudo docker version
Client version: 0.11.1
Client API version: 1.11
Go version (client): go1.2.1
Git commit (client): fb99f99/0.11.1
Server version: 0.11.1
Server API version: 1.11
Git commit (server): fb99f99/0.11.1
Go version (server): go1.2.1
Last stable version: 1.0.0, please update docker
```

Pull the Oracle Linux 6.5 Docker image from the repository.  This was created via https://github.com/yasushiyy/docker-oraclelinux6

Image was created in the following way:
* use official centos:centos6 image
* convert into Oracle Linux 6.5 https://linux.oracle.com/switch/centos/
* fix missing MAKEDEV error
* fix locale warning
* install vim
* install oracle-rdbms-server-12cR1-preinstall
* fix libnss_files.so to use /tmp/hosts instead of /etc/hosts https://gist.github.com/lalyos/9525120
* create install directories
* add ORACLE_XX environment variables

```
[vagrant@localhost ~]$ sudo docker pull yasushiyy/oraclelinux6
Pulling repository yasushiyy/oraclelinux6
  :
```

## Install Database

Connect to the container.  Change hostname.  Switch to oracle user.

```
[vagrant@localhost ~]$ sudo docker run --privileged -t -i -v /vagrant:/vagrant yasushiyy/oraclelinux6 /bin/bash 

bash-4.1# hostname -v db12c
bash-4.1# echo "127.0.0.1  localhost localhost.localdomain db12c" > /tmp/hosts

bash-4.1# su - oracle
```

Install ORACLE_HOME using OUI.

```
[oracle@db12c ~]$ /vagrant/database/runInstaller -silent -showProgress -ignorePrereq -responseFile /vagrant/db12c.rsp 
Starting Oracle Universal Installer…
  :
The installation of Oracle Database 12c was successful.
Please check '/opt/oraInventory/logs/silentInstall2014-06-14_04-46-46PM.log' for more details.

As a root user, execute the following script(s):
     1. /opt/oraInventory/orainstRoot.sh
     2. /opt/oracle/product/12.1.0/dbhome_1/root.sh


..................................................   100% Done.
Successfully Setup Software.
 
[oracle@db12c ~]$ exit

bash-4.1# /opt/oraInventory/orainstRoot.sh
Changing permissions of /opt/oraInventory.
Adding read,write permissions for group.
Removing read,write,execute permissions for world.

Changing groupname of /opt/oraInventory to oinstall.
The execution of the script is complete.
 
bash-4.1# /opt/oracle/product/12.1.0/dbhome_1/root.sh
Check /opt/oracle/product/12.1.0/dbhome_1/install/root_db12c.localdomain_2014-06-14_16-53-00.log for the output of root script

bash-4.1# su - oracle
```

Create listener using netca.

```
[oracle@db12c ~]$ netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp

Parsing command line arguments:
    Parameter "silent" = true
    Parameter "responsefile" = /opt/oracle//product/12.1.0/dbhome_1/assistants/netca/netca.rsp
Done parsing command line arguments.
Oracle Net Services Configuration:
Profile configuration complete.
Oracle Net Listener Startup:
    Running Listener Control:
      /opt/oracle/product/12.1.0/dbhome_1/bin/lsnrctl start LISTENER
    Listener Control complete.
    Listener started successfully.
Listener configuration complete.
Oracle Net Services configuration successful. The exit code is 0 
``` 

Create database using dbca.

```
[oracle@db12c ~]$ dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbName corcl -sysPassword oracle -systemPassword oracle -emConfiguration NONE -datafileDestination /opt/datafile -storageType FS -characterSet AL32UTF8
Copying database files
1% complete
3% complete
11% complete
18% complete
26% complete
33% complete
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
Look at the log file "/opt/oracle/cfgtoollogs/dbca/corcl/corcl.log" for further details. 
```

Test connection.

```
[oracle@db12c ~]$ sqlplus system/oracle@localhost:1521/corcl

SQL*Plus: Release 12.1.0.1.0 Production on Sun Jun 15 06:08:07 2014

Copyright (c) 1982, 2013, Oracle.  All rights reserved.


Connected to:
Oracle Database 12c Enterprise Edition Release 12.1.0.1.0 - 64bit Production
With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options

SQL> select * from dual;

D
-
X

SQL> select count(1) from user_tables;

  COUNT(1)
----------
       178

SQL> exit
Disconnected from Oracle Database 12c Enterprise Edition Release 12.1.0.1.0 - 64bit Production
With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options
``` 

