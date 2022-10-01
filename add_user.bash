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
	echo "server_variables file does not exists"
	exit 1
fi

if [ ! -f last_octet ]; then
	echo "last_octet file does not exists"
	exit 1
fi

source server_variables
source last_octet

TG_SEND=$(which telegram-send)
if [ ! -f "$TG_SEND" ]; then
	printf "ERROR: The telegram-send not installed.\n"
	printf "FIX: Please install telegram-send using pip(pip install telegram-send)\n"
	exit 1
fi

QR=$(which qrencode)
if [ ! -f "$QR" ]; then
	printf "ERROR: The qrencode not installed.\n"
	printf "FIX: Please install qrencode using apt(apt install qrencode)\n"
	exit 1
fi

WG=$(which wg)
if [ ! -f "$WG" ]; then
	printf "ERROR: The wireguard not installed.\n"
	printf "FIX: Please install wireguard using apt(apt install wireguard)\n"
	printf "FIX: If you use Ubuntu ≤ 19.04 first add wireguard ppa\n"
	printf "FIX: add-apt-repository ppa:wireguard/wireguard\n"
	exit 1
fi

clients_folder=clients

if [ ! -d $clients_folder ]; then
	mkdir $clients_folder
fi

mkdir $clients_folder/$client_name

preshared=$(wg genpsk)
printf $preshared >$clients_folder/$client_name/preshared

privatekey=$(wg genkey)
printf $privatekey >$clients_folder/$client_name/privatekey

publickey=$(wg pubkey <./$clients_folder/$client_name/privatekey)
printf $publickey >$clients_folder/$client_name/publickey

server_public=$(wg show $wg_interface | grep public | awk '{print $3}')

server_port=$(wg show $wg_interface | grep port | awk '{print $3}')
endpoint="$server_ip:$server_port"

printf "[Interface]\nPrivateKey = $privatekey\nAddress = $wg_network.$last_octet/24\nDNS = 1.1.1.1, 8.8.8.8\n\n[Peer]\nPublicKey = $server_public\nPresharedKey = $preshared\nAllowedIPs = 0.0.0.0/0\nEndpoint = $endpoint\nPersistentKeepalive = 25" >$clients_folder/$client_name/wg.conf
printf "###$client_name config###\n[Peer]\nPublicKey = $publickey\nPresharedKey = $preshared\nAllowedIPs = $wg_network.$last_octet/32\n###End $client_name config###\n" >$clients_folder/$client_name/for_server_config.conf
cat $clients_folder/$client_name/for_server_config.conf >>/etc/wireguard/$wg_interface.conf

systemctl restart wg-quick@$wg_interface

((last_octet++))
printf "last_octet=$last_octet" >last_octet

$QR -t ansiutf8 <$clients_folder/$client_name/wg.conf
$QR -o $clients_folder/$client_name/$client_name-qr.png <$clients_folder/$client_name/wg.conf

printf "$client_name client config for $(hostname) server" | $TG_SEND --stdin
$TG_SEND --image $clients_folder/$client_name/$client_name-qr.png --caption "Client config"
$TG_SEND --file $clients_folder/$client_name/wg.conf
