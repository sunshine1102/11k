#!/bin/bash

#squid install
ins_check=`apt list --installed | grep squid | wc -l`

if [ "$ins_check" == 0 ]; then

apt update -y
apt install squid  apache2-utils -y

echo "auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
    auth_param basic realm proxy
    acl authenticated proxy_auth REQUIRED
    http_access allow authenticated
    http_access allow all
    server_persistent_connections on" >> /etc/squid/squid.conf

echo "include /etc/squid/proxysquid.conf" >> /etc/squid/squid.conf
#installation finished
fi



echo "Starting port: ";
read port_start
echo "Ending port: ";
read port_end
echo "Username: ";
read user
echo "Password: ";
read pass
echo "Interface: ";
read interface
echo "IPv6 network: ";
read network
echo "IPv4 primary IP: ";
read ip;


count=1
cmd_ip="/sbin/ip"
interface="$interface"
network="$network"
#gateway="2a01:4ff:1f0:c653::1"
sleeptime="2s"

# -----
# Generate Random Address

GenerateAddress() {
  array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
  a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
  echo $network::$a
}

# -----
#generate username and pass
htpasswd -bc /etc/squid/passwords $user $pass
# Run IPv6-Address-Loop
# -----
for ((i="$port_start"; i<="$port_end"; i++))
do 
  ip1=$(GenerateAddress)
  $cmd_ip -6 addr add $ip1/64 dev $interface
  myip6=`ip addr show dev $interface | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d' | head -n 1`




echo " "
echo "$ip:$i:$user:$pass => $myip6  $count" >> proxylist.txt
echo "$ip:$i:$user:$pass => $myip6  $count"

#creating user & pass
echo "http_port $i" >> /etc/squid/proxysquid.conf
echo "acl user$i myportname $i" >> /etc/squid/proxysquid.conf
echo "tcp_outgoing_address  $myip6 user$i" >> /etc/squid/proxysquid.conf



  ((count++))
  sleep $sleeptime

done

#restart squid
systemctl restart squid.service
