#!/bin/tcsh
echo "[`date`] [monit] stopping bgp_simple.pl..." >> /usr/local/var/nfsen/blackHole.plugin.log
kill `ps -auxww | grep bgp_simple.pl | grep -v grep | awk '{print $2}'`
sleep 3
echo "[`date`] [monit] start bgp_simple.pl..." >> /usr/local/var/nfsen/blackHole.plugin.log
/usr/local/libexec/nfsen/plugins/bgp_simple.pl -myas 65535 -myip 10.113.0.5 -peerip 10.113.0.6 -peeras 65535 -p /usr/local/var/nfsen/blackhole-pref.td2 -v -o /usr/local/var/nfsen/blackHole.plugin.log &


