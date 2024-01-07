#!/bin/bash
echo "ejecutado"
echo "Inserta tu rango de ip:"
echo "Ejemplo: 192.168.G.0. Rango es igual a G"
read ip
echo "network:" > /etc/netplan/00-installer-config.yaml
echo "  ethernets:" >> /etc/netplan/00-installer-config.yaml
echo "    enp0s3:" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp4: true" >> /etc/netplan/00-installer-config.yaml
echo "    enp0s8:" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp4: false" >> /etc/netplan/00-installer-config.yaml
echo "      addresses: [192.168.$ip.1/25]" >> /etc/netplan/00-installer-config.yaml
echo "      nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "        addresses: [127.0.0.1]" >> /etc/netplan/00-installer-config.yaml
echo "    enp0s9:" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp4: false" >> /etc/netplan/00-installer-config.yaml
echo "      addresses: [192.168.$ip.129/25]" >> /etc/netplan/00-installer-config.yaml
echo "      nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "        addresses: [127.0.0.1]" >> /etc/netplan/00-installer-config.yaml
netplan apply

apt update && apt upgrade -y --autoremove
apt purge isc-dhcp-server bind9 -y
apt install isc-dhcp-server bind9 -y

#echo 'INTERFACESv4="enp0s8 enp0s9"' > /etc/default/isc-dhcp-server
#echo 'INTERFACESv6=""' >> /etc/default/isc-dhcp-server
echo "subnet 192.168.$ip.0 netmask 255.255.255.128 {" >> /etc/dhcp/dhcpd.conf
echo "  range 192.168.$ip.11 192.168.$ip.126;" >> /etc/dhcp/dhcpd.conf
echo "  option routers 192.168.$ip.1;" >> /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers 192.168.$ip.1;" >> /etc/dhcp/dhcpd.conf
#echo "  option domain-name 'iortega.test';" >> /etc/dhcp/dhcpd.conf
echo "  default-lease-time 60;" >> /etc/dhcp/dhcpd.conf
echo "  max-lease-time 60;" >> /etc/dhcp/dhcpd.conf
echo "}" >> /etc/dhcp/dhcpd.conf

echo "subnet 192.168.$ip.128 netmask 255.255.255.128 {" >> /etc/dhcp/dhcpd.conf
echo "  range 192.168.$ip.139 192.168.$ip.254;" >> /etc/dhcp/dhcpd.conf
echo "  option routers 192.168.$ip.129;" >> /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers 192.168.$ip.129;" >> /etc/dhcp/dhcpd.conf
#echo "  option domain-name 'iortega.test';" >> /etc/dhcp/dhcpd.conf
echo "  default-lease-time 60;" >> /etc/dhcp/dhcpd.conf
echo "  max-lease-time 60;" >> /etc/dhcp/dhcpd.conf
echo "}" >> /etc/dhcp/dhcpd.conf

systemctl restart isc-dhcp-server

grupo="grup$ip"
echo "zone \"$grupo.test\" IN {" > /etc/bind/named.conf.local
echo '  type master;' >> /etc/bind/named.conf.local
echo "  file \"/etc/bind/db.$grupo.test\";" >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

echo "zone \"$ip.168.192.in-addr.arpa\" IN {" >> /etc/bind/named.conf.local
echo '  type master;' >> /etc/bind/named.conf.local
echo "  file \"/etc/bind/db.$ip.168.192\";" >> /etc/bind/named.conf.local
echo '};' >> /etc/bind/named.conf.local

rm /etc/bind/db.$grupo.test
touch /etc/bind/db.$grupo.test

echo '$TTL 604800' > /etc/bind/db.$grupo.test
echo "@		IN	SOA	$grupo.test.	root.$grupo.test. (" >> /etc/bind/db.$grupo.test
echo "				3		; Serial" >> /etc/bind/db.$grupo.test
echo "				604800		; Refresh" >> /etc/bind/db.$grupo.test
echo "				86400		; Retry" >> /etc/bind/db.$grupo.test
echo "				2419200		; Expire" >> /etc/bind/db.$grupo.test
echo "				604800 )	; Negative Cache TTL" >> /etc/bind/db.$grupo.test
echo ";" >> /etc/bind/db.$grupo.test
echo "@ IN NS server.$grupo.test." >> /etc/bind/db.$grupo.test
echo "server.$grupo.test. IN A 192.168.$ip.1" >> /etc/bind/db.$grupo.test
#echo "" >> /etc/bind/db.$grupo.test

rm /etc/bind/db.$ip.168.192
touch /etc/bind/db.$ip.168.192

echo '$TTL 604800' > /etc/bind/db.$ip.168.192
echo "@		IN	SOA	$grupo.test.	root.$grupo.test. (" >> /etc/bind/db.$ip.168.192
echo "				3		; Serial" >> /etc/bind/db.$ip.168.192
echo "				604800		; Refresh" >> /etc/bind/db.$ip.168.192
echo "				86400		; Retry" >> /etc/bind/db.$ip.168.192
echo "				2419200		; Expire" >> /etc/bind/db.$ip.168.192
echo "				604800 )	; Negative Cache TTL" >> /etc/bind/db.$ip.168.192
echo ";" >> /etc/bind/db.$ip.168.192
echo "@ IN NS server.$grupo.test." >> /etc/bind/db.$ip.168.192
echo "1 IN PTR server$grupo.test." >> /etc/bind/db.$ip.168.192
#echo "" >> /etc/bind/db.$grupo.test

systemctl restart bind9

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
apt install iptables-persistent
#hostname set-hostname $grupo

