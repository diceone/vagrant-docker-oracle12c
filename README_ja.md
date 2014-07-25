vagrant-docker-oracle12c
========================

[English version here](README.md)

Vagrant + Docker + Oralce Linux 6.5 + Oracle Database 12cR1 (Enteprise Edition) シングルDB環境の簡易セットアップ手順。 OS周りは自動セットアップ、DB周りもSilent InstallによりGUI(X)なしでのセットアップが可能。

Databaseのバイナリは別途ダウンロードが必要。

Silent Install部分も自動化しても良いのだが、個人的にそこは目で見ながら手動でやったほうが良いと思う。

as of 6/15/2014

## 環境

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

## ダウンロード

Database のバイナリを以下からダウンロード。"database"というサブディレクトリになるはず。

http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html

* linuxamd64_12c_database_1of2.zip
* linuxamd64_12c_database_2of2.zip

## Vagrant設定

プロキシを利用する必要がある場合、まず vagrant-proxyconf をインストールする。

```
(MacOSX)
$ export http_proxy=proxy:port
$ export https_proxy=proty:port

(Windows)
$ set http_proxy=proxy:port
$ set https_proxy=proxy:port

$ vagrant plugin install vagrant-proxyconf
```

VirtualBox plugin をインストールする。

```
$ vagrant plugin install vagrant-vbguest
```

本レポジトリをローカルディスク上にcloneする。先ほどの"database"サブディレクトリを本ディレクトリ内にMOVEする。
```
$ git clone https://github.com/yasushiyy/vagrant-docker-oracle12c
$ cd vagrant-docker-oracle12c
 ```

プロキシを利用する必要がある場合、追加で Vagrantfile の編集が必要。

```
config.proxy.http     = "http://proxy:port"
config.proxy.https    = "http://proxy:port"
config.proxy.no_proxy = "localhost,127.0.0.1"
```

## ホストOSインストール (Vagrant)

`vagrant up`を実行すると、内部的に以下が動く。
* CentOS6.5のダウンロードと起動
* Oracle Linuxへの変換 https://linux.oracle.com/switch/centos/
* locale関連warningへの対処
* oracle-rdbms-server-12cR1-preinstall のインストール
* docker-io のインストール
* UEKR2のインストール、デフォルト化

```
$ vagrant up
   :
==> default: Oracle Linux Server release 6.5
```

リブートしてUEKR2を利用。NUMAとTransparent HugepageがOFFになっていることを確認。

```
$ vagrant reload

$ vagrant ssh
Last login: Thu Jun 12 12:28:48 2014 from 10.0.2.2

[vagrant@localhost ~]$ dmesg | more
Initializing cgroup subsys cpuset
Initializing cgroup subsys cpu
Linux version 2.6.39-400.215.2.el6uek.x86_64 (mockbuild@ca-build44.us.oracle.com) (gcc version 4.4.6 20110731 (Red Hat 4.4.6-3) (GCC) ) #1 SMP Fri Jun 6 12:51:44 PDT 2014
Command line: ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 rd_LVM_LV=VolGroup/lv_root  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet numa=off transparent_hugepage=never
   :

[vagrant@localhost ~]$ exit

```

## コンテナOSインストール (Docker)

CentOS6.5のDocker Imageに対して以下を実施済みのイメージをダウンロードする。
* centos:centos6を利用
* Oracle Linuxへの変換 https://linux.oracle.com/switch/centos/
* MAKEDEVが足りないエラーへの対処
* locale関連warningへの対処
* oracle-rdbms-server-12cR1-preinstall のインストール
* vim のインストール
* libnss_files.so を書き換えて /etc/hosts の代わりに /tmp/hosts を利用させる https://gist.github.com/lalyos/9525120
* DBインストールディレクトリ作成
* ORACLE_HOME等の環境変数設定

```
$ vagrant ssh

[vagrant@localhost ~]$ sudo docker pull yasushiyy/vagrant-docker-oracle12c
```

## DBインストール

コンテナに接続し、ホスト名およびユーザ設定を行う。

```
[vagrant@localhost ~]$ sudo docker run --privileged -p 11521:1521 -t -i -v /vagrant:/vagrant yasushiyy/vagrant-docker-oracle12c /bin/bash

bash-4.1# hostname -v db12c
bash-4.1# echo "127.0.0.1  localhost localhost.localdomain db12c" > /tmp/hosts

bash-4.1# su - oracle
```

OUIにてDBバイナリをインストールする。

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

netcaでリスナーを作成する。

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

dbcaでDBを作成する。

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

接続テスト。

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
