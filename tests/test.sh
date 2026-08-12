#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin" "$TMP/etc/pve" "$TMP/var/lib"
cp "$ROOT/tests/fixtures/Nodes.pm" "$TMP/Nodes.pm"

cat > "$TMP/bin/getent" <<'EOF'
#!/bin/sh
if [ "$1" = passwd ] && [ "$#" -eq 2 ]; then
    [ "$2" = testuser ] && printf 'testuser:x:1000:1000::/home/testuser:/bin/bash\n'
    exit 0
fi
if [ "$1" = passwd ]; then
    printf 'testuser:x:1000:1000::/home/testuser:/bin/bash\n'
fi
EOF
chmod +x "$TMP/bin/getent"

cat > "$TMP/bin/systemctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_SYSTEMCTL_LOG"
EOF
chmod +x "$TMP/bin/systemctl"

cat > "$TMP/etc/pve/pve-auto-login.conf" <<'EOF'
testuser@pam
EOF

PATH="$TMP/bin:$PATH" \
PVE_AUTO_LOGIN_TESTING=1 \
PVE_AUTO_LOGIN_STATE_FILE="$TMP/etc/pve/pve-auto-login.conf" \
PVE_AUTO_LOGIN_TARGET="$TMP/Nodes.pm" \
TEST_SYSTEMCTL_LOG="$TMP/systemctl.log" \
  "$ROOT/pve-auto-login" --apply-local --quiet

grep -q "testuser@pam" "$TMP/Nodes.pm"
grep -q "restart pvedaemon.service pveproxy.service" "$TMP/systemctl.log"

cp "$TMP/Nodes.pm" "$TMP/changed-before"
sed -i 's/defined(\$param->{cmd})/defined(\$param->{unexpected})/' "$TMP/Nodes.pm"
cp "$TMP/Nodes.pm" "$TMP/incompatible-before"
if PATH="$TMP/bin:$PATH" \
    PVE_AUTO_LOGIN_TESTING=1 \
    PVE_AUTO_LOGIN_STATE_FILE="$TMP/etc/pve/pve-auto-login.conf" \
    PVE_AUTO_LOGIN_TARGET="$TMP/Nodes.pm" \
    TEST_SYSTEMCTL_LOG="$TMP/systemctl.log" \
    "$ROOT/pve-auto-login" --apply-local --quiet; then
    echo "expected incompatible fixture to fail" >&2
    exit 1
fi
cmp -s "$TMP/Nodes.pm" "$TMP/incompatible-before"

echo "all tests passed"
