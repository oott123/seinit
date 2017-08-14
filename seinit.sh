#!/bin/bash
set -e
set -x
# PM detect
if (which apt-get > /dev/null); then
  PM=apt-get
elif (which yum > /dev/null); then
  PM=yum
fi
if [ "$PM" == "" ]; then
  echo "Nither apt-get nor yum is found."
  exit 1
fi
# Functions
function installPackage () {
  $PM install -y "$@"
}
function installPackageYumOnly () {
  if [ $PM == "yum" ]; then
    yum install -y "$@"
  fi
}
function installPackageAptOnly () {
  if [ $PM == "apt-get" ]; then
    apt-get install -y "$@"
  fi
}
function suckIPv6 () {
  if [ $PM == "apt-get" ]; then
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
  elif [ $PM == "yum" ]; then
    sed -i 's/^ip_resolve/#ip_resolve/g' /etc/yum.conf
    echo 'ip_resolve=4' >> /etc/yum.conf
  fi
}
function updatePMMetadata () {
  if [ $PM == "apt-get" ]; then
    [ $SEI_BACKUP ] && cp /etc/apt/sources.list ~/.seinit/sources.list
    sed -i 's#^deb [^ ]* #deb mirror://mirrors.ubuntu.com/mirrors.txt #g' /etc/apt/sources.list
    apt-get update
  elif [ $PM == "yum" ]; then
    yum makecache
  fi
}
function importSSHKeys () {
  [ -d ~/.ssh ] || mkdir ~/.ssh
  [ $SEI_BACKUP ] && cp -r ~/.ssh ~/.seinit/dot_ssh
  chmod 755 ~/.ssh
  echo -e "ssh-rsa
AAAAB3NzaC1yc2EAAAADAQABAAACAQDLu2oMKdYw4zFvHvG4cQasFWGF9epC8mzqrsHIg7QaerrwIUjui0alLeFQy6QiwUyKzFz3U5kT0fMfKrC9bBCKfnbT+xahSOMyEBqxOVi87Lzj5fVkTCnPpgMuS1YTnKaTHhBwjg1bi/kwXvr10zqeNtzQF+v0nVTVSAav4rQWeNJmXkW26+gsG85SPT7MKQr/+K3RClsa3qBJSTyif1Ha6M+kgUo+rojjw9adPwF7AjSyRd9Ns6IjQhskC5YvzANLLGlLLKka7qkXnlc2eaN+6hu0NDCpsoigoBfND4/owqZLDzH84SSB0eliqPHvOSnX+siUQPs0eFfIp7izH+gFC4rHGexutZSieXKQQwV68utZXYiPcBcH/PLsfQPoLv16mEVpzmxd0JwH43f0HRew/DkS+agL4YNQBOECtxa4pcbz1/EUwfIpZwmMz9eppFrLFFjXNMvYdSKsOlAGbIux5It7hDvmpdplGIva3iwXb28wGzjpkTMBomC+oHT5zIF9ptZyS5EuW68peUGmUWTAsNnsDeB56Rvz7xDfMWCrOc5d0smBepfjy+dBpichhvlhDFqYcamwEW6VNYGP/9awsnkvlb5nIhxQsxsoL8pg5b3+BmUxBLgxj/hTDezU9hArUDqxxaUR9hSnC+BS+lHjvp5tiF3nel8ww9FC17KSww== oott123@device0\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+NF5g0Q/0nlkrawFGbGq4E2EBg/KWN9wzPlTVPZXhcxFeeMzrSSP6y2WuwvmcQzJfnN2WsnvbJsQpkj1/R1zz+Bg6GaS1Z+1USCL6/KU0Jf2fBDMJKENAxX5TUT1WfYUrGhc0utE8wahCZ9MdbkrS33fxYeUdNic9sadbQFYHm3lvcAuYB/G6EzTUWwH5f65pDNhO4m/zeftGTwqCoatvYpSUJVnzCaSvtsz5EEv6QTI3kAPLAsAYv8MWZiyoHLfXMC8+2fDCIJqrMZKfWgGYheqe4JduZlOkhRcQ4NHovqLlUA9J0iuZ5PKupRo8ocwL85RlaeDe2gTY/CNDiYGR notroot@notroot\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtv8RhG4uX9bWc4sh3gPj8Umrcfk0/AcqWkyWM4pX4vFvF33NjNcIimAMJ/Bl78MhMbee3EW/j0sB1bnbi1wiMhxOX54RE95/0wMnThM0tN2Vu+nY+nXqoVCZoyJY6oVENCXgxxEZwfdN42+9k4vtAMiQJsxKj5BtmsEOWXl86E0+e/19XnGzuRnzqJiC8Ep48QK0Sa8FLGoEg4SxbqkeLVIUuZyYEMeEmUz1JKcUmPBFqBmCwevrmYI9wBVIGyYhPl8ktGYsm7HU8sr/pTtaD6sZH0CUjW4/FWgZ2JVCkMVC/P+v3dq/MsZ3UcsY+LM/psgstZQCTYwK/bC6CTdco+lxAVcbMULTPotslYRxMlvE0KpTAxrzTbbGkKrA1XGOm+o8Jdss9jdQpMs3AhuNFgz4iMRh1iCXdC/pFU+XSW4+WMdEjFkVy+jTJMCuYuMVLue3g2rTm4vOdGbAhNJGgf1URK4Yxr2WEG/0vc6GmV2RaQpHHFoE15cNbgx8tGS0PrPQBVxY1Nos1wrTwY8EC3170UtMKwRkoM4wKWbWug7oY6qArBrrdFFGh4IrV/cnuZMGrwcaL2JazkyWc9bz+7pDeZDGwECtqAok7jz+LgLFgY02d+wKwkUKHq489/aQ1v/SYl1w+4egBWFSrHEPEiI2MlDWIUHFBqolJpGf56w== oott123@phone\n" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
}
function installByobu () {
  installPackage byobu
  [ $SEI_BACKUP ] && cp /usr/share/byobu/profiles/tmux ~/.seinit/tmux
  echo "set-window-option -g allow-rename off" >> /usr/share/byobu/profiles/tmux
}
function changeSSHPort () {
  local PORT=$1
  sed -i 's/^ListenAddress/#ListenAddress/g' /etc/ssh/sshd_config
  sed -i 's/^Port/#Port/g' /etc/ssh/sshd_config
  echo '# sei init changed ssh port' >> /etc/ssh/sshd_config
  echo "Port $PORT" >> /etc/ssh/sshd_config
}
function disableSSHRootLoginWithPassword () {
  sed -i 's/^PermitRootLogin/#PermitRootLogin/g' /etc/ssh/sshd_config
  echo '# sei init disabled root login with password' >> /etc/ssh/sshd_config
  echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
}
function enhanceSSHConnection () {
  sed -i 's/^TCPKeepAlive/#TCPKeepAlive/g' /etc/ssh/sshd_config
  sed -i 's/^ClientAliveInterval/#ClientAliveInterval/g' /etc/ssh/sshd_config
  sed -i 's/^ClientAliveCountMax/#ClientAliveCountMax/g' /etc/ssh/sshd_config
  echo '# sei init disabled enhance SSH connection' >> /etc/ssh/sshd_config
  echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
  echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config
  echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config
}
function restartSSHService () {
  service sshd restart || service ssh restart
}
function installOmz () {
  sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
  [ $SEI_BACKUP ] && cp ~/.zshrc ~/.seinit/dot_zshrc
  sed -i 's/^ZSH_THEME=.*$/ZSH_THEME=ys/g' ~/.zshrc
}

# ...
if [ "$SEI_BACKUP" == "" ]; then
  read -p "May I make backup files in ~/.seinit ? [Y/n]" -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    SEI_BACKUP=yes
  fi
fi
if [ $SEI_BACKUP ]; then
  [ -d ~/.seinit ] || mkdir ~/.seinit
  chmod 600 ~/.seinit
fi
if [ `whoami` == "root" ]; then
  if [ "$SEI_FUCK_SSH" == "" ]; then
    read -p "May I FUCK your ssh server? [y/N]" -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      SEI_FUCK_SSH=yes
    fi
  fi
  if [ "$SEI_FUCK_SSH" == "yes" ]; then
    [ $SEI_BACKUP ] && cp /etc/ssh/sshd_config ~/.seinit/sshd_config
    changeSSHPort 33
    disableSSHRootLoginWithPassword
    enhanceSSHConnection
    restartSSHService
  fi
  suckIPv6
  updatePMMetadata
  importSSHKeys
  installPackageYumOnly epel-release
  installByobu
  installPackage zsh wget curl git htop ncdu vim
  installPackageAptOnly progress software-properties-common python-software-properties
else
  installOmz
fi
