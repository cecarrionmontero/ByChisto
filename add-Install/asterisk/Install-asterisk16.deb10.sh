#!/bin/bash
#Instalación de asterisk 16 sobre debian 10

#Update system & reboot
sudo apt update && sudo apt install lsb-release && sudo apt -y upgrade
#sudo reboot

#Install Other dependencies
sudo apt -y install locales snmp snmpd sngrep build-essential aptitude openssh-server apache2 mariadb-server mariadb-client bison doxygen flex php-pear curl sox libncurses5-dev libssl-dev libmariadbclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool-bin autoconf git subversion uuid uuid-dev libiksemel-dev tftpd mailutils nano ntp libspandsp-dev libcurl4-openssl-dev libical-dev libneon27-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libsrtp*-dev unixodbc unixodbc-dev python-dev xinetd e2fsprogs dbus sudo xmlstarlet lame ffmpeg dirmngr linux-headers*

#Install Asterisk 16 LTS dependencies
sudo apt -y install git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev  uuid-dev

#Install freetds
sudo apt -y install unixodbc unixodbc-dev freetds-dev freetds-bin tdsodbc

#Install odbc
wget https://downloads.mariadb.com/Connectors/odbc/connector-odbc-2.0.19/mariadb-connector-odbc-2.0.19-ga-debian-x86_64.tar.gz
tar -zxvf mariadb-connector-odbc-2.0.19*.tar.gz
cp lib/libmaodbc.so /usr/lib/x86_64-linux-gnu/odbc/

#Add odbcinst.ini
cat >> /etc/odbcinst.ini << EOF
[MySQL]
Description = ODBC for MariaDB
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbcmyS.so
FileUsage = 1
[FreeTDS]
Description = ODBC for MSSQL
Driver = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so 
EOF

#Add odbc.ini
cat >> /etc/odbc.ini << EOF
[MySQLodbcAsterisk]
Description = MariaDB connection to 'asteriskcdrdb' database
driver = MySQL
server = localhost
database = asteriskcdrdb
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
option = 3
[MSSQLodbcAsterisk]
Driver = FreeTDS
Server = dbserver.domain.com
Port = 1433
TDS_Version = 7.2
EOF

#Config glonal FreeTDS /etc/freetds/freetds.conf
#Add
cat >> /tmp/temp.txt << EOF
[MSSQLodbcAsterisk] 
host = dbserver.domain.com 
port = 1433 
tds version = 7.2 
EOF
cat "" >> /etc/freetds/freetds.conf
cat /tmp/temp.txt >> /etc/freetds/freetds.conf

#Add universe repository and install subversio
#sudo add-apt-repository universe
sudo apt update && sudo apt -y install subversion

#Download Asterisk 16 LTS tarball
# sudo apt policy asterisk
cd /usr/src/
sudo curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz

#Extract the file
sudo tar xvf asterisk-16-current.tar.gz
cd asterisk-16*/

#download the mp3 decoder library
sudo contrib/scripts/get_mp3_source.sh

#Ensure all dependencies are resolved
sudo contrib/scripts/install_prereq install