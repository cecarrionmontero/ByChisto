#!/bin/bash

#Update system & reboot
sudo apt update -y && sudo apt install lsb-release -y  && sudo apt -y upgrade

#Install Other dependencies
sudo apt -y install locales snmp snmpd sngrep build-essential aptitude openssh-server apache2 mariadb-server mariadb-client bison doxygen flex php-pear curl sox libncurses5-dev libssl-dev libmariadbclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool-bin autoconf git subversion uuid uuid-dev libiksemel-dev tftpd mailutils nano ntp libspandsp-dev libcurl4-openssl-dev libical-dev libneon27-dev libasound2-dev libogg-dev libvorbis-dev libicu-dev libsrtp*-dev unixodbc unixodbc-dev python-dev xinetd e2fsprogs dbus sudo xmlstarlet lame ffmpeg dirmngr linux-headers*

#Install Asterisk 16 LTS dependencies
sudo apt -y install git curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev  uuid-dev

#Install freetds
sudo apt -y install unixodbc unixodbc-dev freetds-dev freetds-bin tdsodbc

#Install odbcMysql
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

#Config global FreeTDS /etc/freetds/freetds.conf
#Add
cat >> /tmp/temp.txt << EOF
[MSSQLodbcAsterisk] 
host = dbserver.domain.com 
port = 1433 
tds version = 7.2 
EOF
cat "" >> /etc/freetds/freetds.conf
cat /tmp/temp.txt >> /etc/freetds/freetds.conf

#Add universe repository and install subversion
sudo apt update && sudo apt -y install subversion

#Download Asterisk 16
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

#Run the configure script to satisfy build dependencies
sudo ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled

#Setup menu options by running the following command:
sudo make menuselect.makeopts
sudo menuselect/menuselect --enable app_macro --enable format_mp3 --enable chan_ooh323 --enable chan_mobile --enable format_mp3 --enable codec_opus --enable codec_silk menuselect.makeopts
sudo make
sudo make install
sudo make samples
sudo make config

#Create user and group to run asterisk
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk
sudo chown -R asterisk.asterisk /etc/asterisk
sudo chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk.asterisk /usr/lib64/asterisk

#Restart asterisk service
sudo systemctl restart asterisk

#Enable asterisk service to start on system  boot
sudo systemctl enable asterisk

#Test to see if it connect to Asterisk CLI
sudo asterisk -rvv

#Mod /etc/asterisk/asterisk.conf
sed -i 's/;highpriority = yes/highpriority = yes/g' /etc/asterisk/asterisk.conf
sed -i 's/;maxcalls = 10/maxcalls = 5000/g' /etc/asterisk/asterisk.conf
sed -i 's/;maxfiles = 1000/maxfiles = 200000/g' /etc/asterisk/asterisk.conf

#Config SNMP
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.old
rm -rf /etc/snmp/snmpd.conf

cat >> /etc/snmp/snmpd.conf << EOF
rocommunity MyServices
syslocation Universe10 - IT Room
sysContact Zamasu <zamasu@hdc>;
master          agentx
agentXSocket /var/agentx/master
agentXPerms 0660 0550
EOF

systemctl enable snmpd
systemctl start snmpd
systemctl status snmpd

snmpwalk -v2c -c MyServices 127.0.0.1 

#open ports in ufw firewall
sudo apt install -y ufw 
sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
sudo ufw allow proto udp from any to any port 5060,5061
sudo ufw allow proto tcp from any to any port 5060,5061
sudo ufw allow 10000:65000/udp
sudo ufw allow 161
sudo ufw enable
