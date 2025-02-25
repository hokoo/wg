#!/usr/bin/env bash

# add-apt-repository -y ppa:wireguard/wireguard

if [ -z "$1" ]; then
	echo "No wg name"
	exit 1
fi

client_name=$1

if [ -d $client_name ]; then
	echo "Client exist!"
	exit 1
fi

bash init_files.bash

if [ ! -f server_variables ]; then
	echo "No server_variables file!"
	exit 1
fi

if [ ! -f last_octet ]; then
	echo "No last_octet_file!"
	exit 1
fi

clients_folder=clients

if [ ! -d $clients_folder ]; then
	mkdir $clients_folder
fi

apt-get update
apt-get -y install wireguard curl
apt-get -y install python3-pip
pip3 install telegram-send
apt install qrencode

source server_variables
source last_octet

mkdir $clients_folder/$client_name

preshared=$(wg genpsk)
printf $preshared >$clients_folder/$client_name/preshared

privatekey=$(wg genkey)
printf $privatekey >$clients_folder/$client_name/privatekey

publickey=$(wg pubkey <./$clients_folder/$client_name/privatekey)
printf $publickey >$clients_folder/$client_name/publickey

printf "[Interface]\nPrivateKey = $privatekey\nAddress = $wg_network.$last_octet/24\nListen Port = $server_port\nPostUp = iptables -A FORWARD -i $wg_interface -j ACCEPT; iptables -t nat -A POSTROUTING -o $internal_interface -j MASQUERADE; ip6tables -A FORWARD -i $wg_interface -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $internal_interface -j MASQUERADE\nPostDown = iptables -D FORWARD -i $wg_interface -j ACCEPT; iptables -t nat -D POSTROUTING -o $internal_interface -j MASQUERADE; ip6tables -D FORWARD -i $wg_interface -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $internal_interface -j MASQUERADE" >$clients_folder/$client_name/for_server_config.conf
#printf "###$client_name config###\n[Peer]\nPublicKey = $publickey\nPresharedKey = $preshared\nAllowedIPs = $wg_network.$last_octet/32\n###End $client_name config###\n" >$clients_folder/$client_name/for_server_config.conf
cat $clients_folder/$client_name/for_server_config.conf >>/etc/wireguard/$wg_interface.conf

systemctl enable wg-quick@$wg_interface
systemctl daemon-reload
systemctl restart wg-quick@$wg_interface

((last_octet++))
printf "last_octet=$last_octet" >last_octet
printf "Don't forget enable ip_forward in sysctl.conf!"
printf "Don't forget set up telegram-send by 'telegram-send --configure' command!"
