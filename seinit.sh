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
  echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAyMczv8YIzNi5nrOlPHSWxMVt3zt+ZKPS1dzimMXgGZ+/JW3wB39WToVdYYpcRBV54CR6Z15qjlLFVwjIPZlTs11s6NOU5EsZbx/lVK5tVfTYTAHA2n1bSmU2D2TvxxwfcvGPe6ELy0uhoHzD9VwzLdjdKTBqG8GjuYe1MDmH1rM= oott123@laptop\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEA1+1X757LAH3P7H3Pp8rzp5rFuHrwF8rrwiQxJ72t5Mv1FbcF2uoCWehjRpN0Sm7baofxbxxq2np40mQcLfN0W/eigevBxUtbcJf1hSTATfwA9vxZAl6iTMIPMETufSBotcv/TWv+JBSox/76lNR4Va8g7KB9a0nUNWTtaTCE6dE= oott123@Android\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+NF5g0Q/0nlkrawFGbGq4E2EBg/KWN9wzPlTVPZXhcxFeeMzrSSP6y2WuwvmcQzJfnN2WsnvbJsQpkj1/R1zz+Bg6GaS1Z+1USCL6/KU0Jf2fBDMJKENAxX5TUT1WfYUrGhc0utE8wahCZ9MdbkrS33fxYeUdNic9sadbQFYHm3lvcAuYB/G6EzTUWwH5f65pDNhO4m/zeftGTwqCoatvYpSUJVnzCaSvtsz5EEv6QTI3kAPLAsAYv8MWZiyoHLfXMC8+2fDCIJqrMZKfWgGYheqe4JduZlOkhRcQ4NHovqLlUA9J0iuZ5PKupRo8ocwL85RlaeDe2gTY/CNDiYGR notroot@noroot" >> ~/.ssh/authorized_keys
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
