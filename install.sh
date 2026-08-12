#!/bin/sh
set -eu

PREFIX=/usr/local/sbin
COMMAND="$PREFIX/pve-auto-login"
HOOK=/etc/apt/apt.conf.d/90pve-auto-login

if [ "$(id -u)" -ne 0 ]; then
    echo "install.sh must be run as root" >&2
    exit 1
fi

if [ ! -d /etc/pve ] || [ ! -f /usr/share/perl5/PVE/API2/Nodes.pm ]; then
    echo "This does not look like a Proxmox VE node" >&2
    exit 1
fi

install -D -m 0755 pve-auto-login "$COMMAND"

if [ -e "$HOOK" ] && ! grep -qF '/usr/local/sbin/pve-auto-login --apply-local --quiet' "$HOOK"; then
    echo "Refusing to overwrite existing $HOOK" >&2
    exit 1
fi

cat > "$HOOK" <<'EOF'
// Reapply the opt-in PAM console-login allowlist after dpkg transactions.
DPkg::Post-Invoke { "/usr/local/sbin/pve-auto-login --apply-local --quiet"; };
EOF
chmod 0644 "$HOOK"

echo "Installed $COMMAND"
echo "Installed $HOOK"
echo "Run '$COMMAND' to configure users."
