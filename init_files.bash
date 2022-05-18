#!/usr/bin/env bash

if [ ! -f ./server_variables ]; then
	echo "server_variables does not exists. Recreating..."
	cp ./server_variables.example ./server_variables
else
	echo "server_variables exists"
fi

if [ ! -f ./last_octet ]; then
	echo "last_octet does not exists. Recreating..."
	cp ./last_octet.example ./last_octet
else
	echo "last_octet exists"
fi
