[root@localhost yum.repos.d]# cat /etc/yum.repos.d/cloudstack.repo
[cloudstack]
name=cloudstack
baseurl=http://download.cloudstack.org/el/8/4.17/
enabled=1
gpgcheck=0

[root@localhost ~]# yum deplist cloudstack-management cloudstack-common cloudstack-usage cloudstack-cli | awk '/provider:/ {print $2}' | sort -u | grep -v java | grep -v cloudstack | xargs yum install -y

hostnamectl set-hostname localhost --transient

[root@localhost ~]# iptables-restore < /etc/sysconfig/iptables
iptables -F ?

[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# systemctl disable firewalld

rm -fr /var/lib/mysql/*

[root@localhost ~]# systemctl stop mysqld
[root@localhost ~]# systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
[root@localhost ~]# systemctl start mysqld
[root@localhost ~]#
[root@localhost ~]# mysql -u root
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.32-log MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'P@ssword123';
ERROR 1290 (HY000): The MySQL server is running with the --skip-grant-tables option so it cannot execute this statement
mysql> flush privileges;
Query OK, 0 rows affected (0.07 sec)

mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'P@ssword123';
Query OK, 0 rows affected (0.06 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.02 sec)

mysql> ^DBye


[root@localhost ~]# systemctl stop mysqld

[root@localhost ~]#
[root@localhost ~]# systemctl unset-environment MYSQLD_OPTS
[root@localhost ~]# systemctl start mysqld
[root@localhost ~]# mysql -u root
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
[root@localhost ~]# mysql -u root -p
Enter password:
Welcome to the MySQL monitor


In /etc/my.cnf:
server-id=1
sql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"
binlog-format = 'ROW'
log-bin=mysql-bin
max_connections=700
innodb_lock_wait_timeout=600
innodb_rollback_on_timeout=1
datadir=/var/lib/mysql

mysql> SHOW VARIABLES LIKE 'validate_password%';
mysql> SET GLOBAL validate_password_length = 5;
mysql> set global validate_password_number_count = 0;
mysql> set global validate_password_mixed_case_count = 0;
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_special_char_count = 0;
Query OK, 0 rows affected (0.00 sec)

mysql> set validate_password_policy = 'LOW';
ERROR 1229 (HY000): Variable 'validate_password_policy' is a GLOBAL variable and should be set with SET GLOBAL
mysql> set global validate_password_policy = 'LOW';
Query OK, 0 rows affected (0.00 sec)
