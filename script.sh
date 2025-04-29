#!/bin/bash

## THIS CONFIG MUST BE RUN IN THE SERVER, YOU CAN DO THIS ON THE CLIENT SIDE BUT YOU MUST CHANGE THE sshd CONFIG FILE AND A WAY TO COPY THE .PUB_KEY TO THE SERVER USER
set -e

echo "== Updating system =="
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install libpam-u2f pamu2fcfg -y

echo "== Enabling SSH =="
sudo systemctl enable ssh
sudo systemctl start ssh

echo "== Backing up SSH config =="
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

echo "== Enabling ChallengeResponseAuthentication =="
sudo sed -i 's/^#*ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "== Registering U2F key for user $USER =="
mkdir -p ~/.config/Yubico

# Prompt the user to touch the Flipper
echo ">>> Plug in your Flipper Zero and press its button when prompted."
pamu2fcfg > ~/.config/Yubico/u2f_keys

echo "== Backing up PAM sshd config =="
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak

read -p "Do you want the U2F prompt BEFORE or AFTER password? (b/a): " ORDER

if [[ "$ORDER" == "b" ]]; then
    sudo sed -i "/@include common-auth/i\\auth required pam_u2f.so origin=ssh://$(hostname) appid=ssh://$(hostname)" /etc/pam.d/sshd
else
    sudo sed -i "/@include common-auth/a\\auth required pam_u2f.so origin=ssh://$(hostname) appid=ssh://$(hostname)" /etc/pam.d/sshd
fi

echo "== Restarting SSH service =="
sudo systemctl restart ssh

echo "== Done! ✅ =="
echo "IMPORTANT: Open a new SSH session to test before closing this one."
