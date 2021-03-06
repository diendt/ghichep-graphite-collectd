#! /bin/bash
eth0_address=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | cut -f2 -d ":" `
read -p "nhap host:" hs
echo "--------CAI DAT VA CAU HINH COLLECTD SERVER-----------------------------"
apt-get update
apt-get install  -y collectd collectd-utils
echo "------------------------------------------------------------------------------"
echo "----------Configure--------------------"
filecollectd=/etc/collectd/collectd.conf
test -f $filecollectd.bka || cp $filecollectd $filecollectd.bka
rm $filecollectd
cat << EOF >>$filecollectd
Hostname "$hs"
FQDNLookup true
Interval 10
ReadThreads 5
LoadPlugin syslog
<Plugin syslog>
        LogLevel info
</Plugin>
# LoadPlugin battery
LoadPlugin cpu
LoadPlugin df
LoadPlugin disk
# LoadPlugin entropy
LoadPlugin interface
# LoadPlugin irq
# LoadPlugin load
LoadPlugin memory
LoadPlugin network
LoadPlugin processes
LoadPlugin rrdtool
# LoadPlugin swap
LoadPlugin users
LoadPlugin write_graphite
<Plugin apache>
   <Instance "Graphite">
        URL "http://$eth0_address/server-status?auto"
      Server "apache"
</Instance>
</Plugin>


#Khai bao cac tuy chon plugin cho df
<Plugin df>
        # ignore rootfs; else, the root file-system would appear twice, causing
        # one of the updates to fail and spam the log
        FSType rootfs
        # ignore the usual virtual / temporary file-systems
        FSType sysfs
        FSType proc
        FSType devtmpfs
        FSType devpts
        FSType tmpfs
        FSType fusectl
        FSType cgroup
        IgnoreSelected true
</Plugin>

<Plugin interface>
        Interface "eth0"
        IgnoreSelected false
</Plugin>
<Plugin network>
Listen "*" "2003"
</Plugin>

<Plugin rrdtool>
DataDir "/var/lib/collectd/rrd"
</Plugin>

# Khai bao de hien thi RAM theo dang % thay vi dung luong
<Plugin memory>
        ValuesAbsolute false
        ValuesPercentage true
</Plugin>

# Khao bao hien thi CPU theo dang % va gop cac CPU neu nhu co nhieu CPU (CPU1, CPU2)
<Plugin cpu>
  ReportByCpu false
  ReportByState true
  ValuesPercentage true
</Plugin>

<Plugin write_graphite>
<Node "graphing">
        Host "localhost"
        Port "2003"
        Protocol "tcp"
        LogSendErrors true
                Prefix "collectd"
                StoreRates true
                AlwaysAppendDS false
                EscapeCharacter "_"
        </Node>
</Plugin>

<Include "/etc/collectd/collectd.conf.d">
        Filter "*.conf"
</Include>
EOF
echo " ---=-KHOI DONG DICH VU--=--------------"
service  collectd restart
service apache2 reload
echo "-----------------------------------------------"
