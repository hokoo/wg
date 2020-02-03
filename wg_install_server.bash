#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo "No user name"
	exit 1
fi

client_name=$1

if [ -d $client_name ]; then
	echo "Client exist!"
	exit 1
fi

if [ ! -f server_variables ]; then
	echo "No server_variables file!"
	exit 1
fi

if [ ! -f last_octet_file ]; then
	echo "No last_octet_file!"
	exit 1
fi

source server_variables
source last_octet_file

WG=$(which wg)
if [ ! -f "$WG" ]; then
	printf "ERROR: The wireguard not installed.\n"
	printf "FIX: Please install wireguard using apt(apt install wireguard)\n"
	printf "FIX: If you use Ubuntu ≤ 19.04 first add wireguard ppa\n"
	printf "FIX: add-apt-repository ppa:wireguard/wireguard\n"
	exit 1
fi

mkdir $client_name

preshared=$(wg genpsk)
printf $preshared >$client_name/preshared

privatekey=$(wg genkey)
printf $privatekey >$client_name/privatekey

publickey=$(wg pubkey <./$client_name/privatekey)
printf $publickey >$client_name/publickey

printf "[Interface]\nPrivateKey = $privatekey\nAddress = $wg_network.$last_octet/24\nListen Port=$server_port\nPostUp = iptables -A FORWARD -i $wg_interface -j ACCEPT; iptables -t nat -A POSTROUTING -o $internal_interface -j MASQUERADE; ip6tables -A FORWARD -i $wg_interface -j ACCEPT; ip6tables -t nat -A POSTROUTING -o $internal_interface -j MASQUERADE\nPostDown = iptables -D FORWARD -i $wg_interface -j ACCEPT; iptables -t nat -D POSTROUTING -o $internal_interface -j MASQUERADE; ip6tables -D FORWARD -i $wg_interface -j ACCEPT; ip6tables -t nat -D POSTROUTING -o $internal_interface -j MASQUERADE" >$client_name/wg.conf
printf "###$client_name config###\n[Peer]\nPublicKey = $publickey\nPresharedKey = $preshared\nAllowedIPs = $wg_network.$last_octet/32\n###End $client_name config###\n" >$client_name/for_server_config.conf
cat $client_name/for_server_config.conf >>/etc/wireguard/$wg_interface.conf

systemctl enable wg-quick@$wg_interface
systemctl daemon-reload
systemctl restart wg-quick@$wg_interface

((last_octet++))
printf "last_octet=$last_octet" >last_octet_file
