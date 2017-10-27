#!/bin/bash

mv /var/lib/mysql /dev/shm
echo "[mysqld]" >> /etc/mysql/my.cnf
echo "datadir = /dev/shm/mysql" >> /etc/mysql/my.cnf

service mysql start & 

sleep 5

echo "CREATE DATABASE homestead" | mysql
echo "SET GLOBAL innodb_buffer_pool_size=750000000; SET GLOBAL innodb_fast_shutdown=2; SET GLOBAL innodb_flush_log_at_trx_commit=0" | mysql
