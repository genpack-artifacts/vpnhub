set -e

ARCH=`uname -m`
ZABBIX_VER=7.0
ZABBIX_REPO=https://repo.zabbix.com/zabbix/$ZABBIX_VER/rhel/9/$ARCH/

for i in zabbix-server-mysql zabbix-sql-scripts zabbix-web-service zabbix-web; do
    download `get-rpm-download-url $ZABBIX_REPO $i` > /tmp/$i.rpm
done

CENTOS_APPSTREAM_REPO=http://ftp.riken.jp/Linux/centos-stream/9-stream/AppStream/$ARCH/os/
for i in mariadb-connector-c net-snmp-libs; do
    # mariadb-connector-c for libmariadbclient.so
    # net-snmp-libs for net-snmp with usmAES256CiscoPrivProtocol
    download `get-rpm-download-url $CENTOS_APPSTREAM_REPO $i` > /tmp/$i.rpm
done

# to enable usmAES256CiscoPrivProtocol
#rm /usr/lib64/libnetsnmp.so.40.2.1

mkdir /tmp/zabbix
for i in /tmp/*.rpm; do
    rpm2targz -O $i | tar zxf - -C /tmp/zabbix 
done

cat << 'EOS' > /tmp/sql
create database `zabbix` character set utf8 collate utf8_bin;
create user zabbix@localhost;
grant all privileges on zabbix.* to zabbix@localhost;
EOS

with-mysql --mysql-plugin=auth_socket.so 'mysql -u root < /tmp/sql' 'zcat /tmp/zabbix/usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u zabbix zabbix'

rm -rf /tmp/zabbix/usr/share/doc /tmp/zabbix/usr/share/man /tmp/zabbix/var
# adjust to merged /usr
if [ -d /tmp/zabbix/usr/sbin ]; then
    mv /tmp/zabbix/usr/sbin /tmp/zabbix/usr/bin
fi

cp -a /tmp/zabbix/. /
chown zabbix /var/log/zabbix
ln -s zabbix_server_mysql /usr/bin/zabbix_server
sed -i 's/^# AllowUnsupportedDBVersions=.*$/AllowUnsupportedDBVersions=1/' /etc/zabbix/zabbix_server.conf
sed -i 's/^# DBSocket=.*$/DBSocket=\/run\/mysqld\/mysqld.sock/' /etc/zabbix/zabbix_server.conf

ln -s /usr/share/fonts/vlgothic/VL-PGothic-Regular.ttf /usr/share/zabbix/assets/fonts/graphfont.ttf
