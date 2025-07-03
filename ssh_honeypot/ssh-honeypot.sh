#! /bin/bash

echo -e "\033[5;38;2;255;186;8m$(curl -s https://raw.githubusercontent.com/REZONAZERO/BashScripts/main/banners/ssh_honeypot.txt)\033[0m"

socat TCP-LISTEN:2222,reuseaddr,fork EXEC:'./fake_ssh.sh' &
trap "kill $!" EXIT
