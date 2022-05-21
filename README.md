# Wireguard endpoint

## Wireguard install and user create
This scripts help you install and configure wireguard server, create users for it and send config for users to you through Telegram.

## Installation


Run 
`bash install.sh <first_user_name>`

If you wanna customize initial settings, first run 
`bash init_files.bash`

and customize server_variables file - set wg interface name, wg port and wg network in it.

Do not forget set up telegram bot by `telegram-send --configure` command.

## Adding users

`bash add_user.bash <new_user_name>`
