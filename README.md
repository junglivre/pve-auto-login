# pve-auto-login

English | [Português](README.br.md)

Opt-in automatic host-console login for local PAM users in Proxmox VE.

Proxmox VE currently special-cases `root@pam` when opening a node shell from the
web UI. This project adds a small, explicit allowlist for additional local PAM
users by applying a narrowly validated patch to `PVE/API2/Nodes.pm`.

The project is designed to be reversible and upgrade-aware:

- the enabled-user list is stored in the cluster filesystem at
  `/etc/pve/pve-auto-login.conf`;
- the patch is applied only when the expected `vncshell` and `spiceshell`
  authorization blocks are both present;
- a failed structural or Perl-syntax check aborts without changing the target;
- a package upgrade hook reapplies the configuration after `dpkg` completes;
- manual changes can be replicated to every cluster node;
- the original target is backed up before the first local patch.

This is an unsupported customization of Proxmox VE internals. Review it before
using it in production and test it on a non-critical node first.

## Requirements

- Proxmox VE 8 or 9
- root access
- local PAM users with valid login shells
- `perl`, `systemctl`, and `ssh` for cluster replication
- optional `whiptail` for the graphical shell menu; a text-menu fallback is used
  when it is unavailable
- passwordless root SSH between cluster nodes for `--apply-all`

## Install

```sh
git clone https://github.com/junglivre/pve-auto-login.git
cd pve-auto-login
sudo ./install.sh
```

The installer places the command at `/usr/local/sbin/pve-auto-login` and adds
the APT hook `/etc/apt/apt.conf.d/90pve-auto-login`.

The installer does not enable any user automatically. If a previous manual
patch is detected, it is imported into the state file as a starting point.

## Usage

```sh
pve-auto-login                 # interactive menu
pve-auto-login --apply-local   # apply on this node only
pve-auto-login --apply-all     # apply to every cluster node
pve-auto-login --status        # inspect state
```

The menu uses `whiptail` when available and falls back to a plain shell menu
otherwise. It writes the shared allowlist and then updates the local/remote nodes.
After a successful patch, `pvedaemon` and `pveproxy` are restarted on affected
nodes so the Perl module is reloaded.

## Upgrade safety

The APT hook runs `pve-auto-login --apply-local --quiet` after a `dpkg`
transaction. It does not blindly edit a new Proxmox file. It requires exactly
two recognizable authorization blocks containing the `cmd != 'login'` guard and
the `root@pam` exception. If the upstream structure changes, it reports the
reason and leaves the file untouched.

The hook is intentionally local-only. Each node reapplies its own package
files when that node is upgraded; normal menu operations use `--apply-all` for
cluster replication. During `--apply-all`, the current script is streamed over
SSH, so peer nodes do not need to have the helper installed beforehand.

## Security notes

This changes who can obtain an automatic shell through the node console. The
users still need the Proxmox `Sys.Console` permission and must be local PAM
users. Do not enable accounts that should not receive an interactive host
shell. The patch does not grant `root`, sudo, or Proxmox permissions.

## Removal

```sh
sudo ./uninstall.sh
```

Uninstallation removes the command and hook but does not erase the shared state
or revert package files automatically. Use `pve-auto-login --disable-all`
before uninstalling if the nodes should return to the upstream behavior.

## Background

<https://forum.proxmox.com/threads/enable-automatic-login-to-host-console-for-non-root-users.96240/>
