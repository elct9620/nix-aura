#!/usr/bin/env bash

echo "Restoring backup files..."

read -p "Do you want to restore the backup files? [y/N] " -n 1 -r yn
if [[ ! $yn =~ ^[Yy]$ ]]; then
    echo "Aborting..."
    exit 1
fi

sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
