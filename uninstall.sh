#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "uninstall.sh must be run as root" >&2
    exit 1
fi

rm -f /usr/local/sbin/pve-auto-login /etc/apt/apt.conf.d/90pve-auto-login
echo "Removed pve-auto-login and its APT hook."
echo "The shared state and any existing Nodes.pm patch were left untouched."
