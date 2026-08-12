# pve-auto-login

[English](README.md) | Português

Login automático no console do host para usuários PAM locais no Proxmox VE.

O Proxmox VE trata `root@pam` de forma especial ao abrir o shell de um nó pela
interface web. Este projeto adiciona uma lista explícita de usuários PAM locais
permitidos, aplicando um patch restrito e validado em `PVE/API2/Nodes.pm`.

## O que o projeto faz

- salva a lista de usuários habilitados em `/etc/pve/pve-auto-login.conf`;
- usa o `/etc/pve`, portanto o estado fica disponível no cluster;
- oferece um menu simples no shell para ativar/desativar usuários;
- valida a estrutura esperada do `Nodes.pm` antes de editar;
- aborta se a estrutura mudou ou se o Perl resultante não compilar;
- cria backup antes do primeiro patch local;
- reinicia `pvedaemon` e `pveproxy` somente quando houve alteração;
- replica manualmente para os demais nós;
- reaplica o patch após upgrades via hook `DPkg::Post-Invoke`.

Esta é uma customização não suportada oficialmente pelo Proxmox VE. Revise o
código e teste primeiro em um nó não crítico.

## Requisitos

- Proxmox VE 8 ou 9;
- acesso root;
- usuários PAM locais com shell de login válido;
- `perl`, `systemctl` e `ssh` para replicação;
- `whiptail` é opcional; sem ele o script usa um menu textual de fallback;
- SSH root sem senha entre os nós para usar `--apply-all`.

## Instalação

```sh
git clone https://github.com/junglivre/pve-auto-login.git
cd pve-auto-login
sudo ./install.sh
```

O instalador instala o comando em `/usr/local/sbin/pve-auto-login` e cria o hook
`/etc/apt/apt.conf.d/90pve-auto-login`.

Nenhum usuário é habilitado automaticamente. Se já existir um patch manual, os
usuários encontrados nele são importados como ponto de partida.

## Uso

```sh
pve-auto-login                 # menu interativo
pve-auto-login --apply-local   # somente este nó
pve-auto-login --apply-all     # todos os nós do cluster
pve-auto-login --status        # consultar estado
```

O menu usa `whiptail` quando disponível e volta automaticamente para o menu
textual quando o pacote não está instalado.

## Segurança em upgrades

Após uma transação do `dpkg`, o hook executa `pve-auto-login --apply-local
--quiet`. Ele não edita cegamente um novo arquivo do Proxmox: exige encontrar
exatamente dois blocos reconhecíveis, com a validação de `cmd != 'login'` e a
exceção de `root@pam`.

Se o Proxmox alterar bastante a estrutura do arquivo, o script informa o motivo
e não modifica nada. Cada nó reaplica localmente quando seus próprios pacotes
são atualizados; o menu usa `--apply-all` para replicar manualmente.

## Segurança

Os usuários continuam precisando da permissão Proxmox `Sys.Console` e devem ser
usuários PAM locais. O script não concede permissões Proxmox, sudo ou root.

## Desinstalação

```sh
sudo ./uninstall.sh
```

A desinstalação remove o comando e o hook, mas não apaga o estado compartilhado
nem reverte automaticamente os arquivos de pacote. Para voltar ao
comportamento original, execute `pve-auto-login --disable-all` antes.

## Referência

<https://forum.proxmox.com/threads/enable-automatic-login-to-host-console-for-non-root-users.96240/>
