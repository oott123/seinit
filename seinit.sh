#!/bin/bash

# taken from https://unix.stackexchange.com/a/421403
bashget() {
  read proto server path <<< "${1//"/"/ }"
  DOC=/${path// //}
  HOST=${server//:*}
  PORT=${server//*:}
  [[ x"${HOST}" == x"${PORT}" ]] && PORT=80

  exec 3<>/dev/tcp/${HOST}/$PORT

  # send request
  echo -en "GET ${DOC} HTTP/1.0\r\nHost: ${HOST}\r\n\r\n" >&3

  # read the header, it ends in a empty line (just CRLF)
  while IFS= read -r line ; do 
      [[ "$line" == $'\r' ]] && break
  done <&3

  # read the data
  nul='\0'
  while IFS= read -d '' -r x || { nul=""; [ -n "$x" ]; }; do 
      printf "%s$nul" "$x"
  done <&3
  exec 3>&-
}

set -xeo pipefail

# PM detect
if (which apt-get > /dev/null); then
  PM=apt-get
  lsbd=$(lsb_release -d)
  case "$lsbd" in
    *Debian*)
      LSB=debian
      ;;
    *Ubuntu*)
      LSB=ubuntu
      ;;
    *)
      echo "Unable to detect your lsb release."
      LSB=unknown
      ;;
  esac
elif (which yum > /dev/null); then
  PM=yum
fi
if [ "$PM" == "" ]; then
  echo "Nither apt-get nor yum is found."
  exit 1
fi

end="\033[0m"
blue="\033[0;34m"

# Functions
function ensureLoc() {
  if [ "$LOC" == "" ]; then
    if (which curl > /dev/null); then
      LOC=$(curl -m 5 -s http://cf-ns.com/cdn-cgi/trace | grep loc | cut -c 5-)
    elif (which wget > /dev/null); then
      LOC=$(wget --timeout=5 -O- http://cf-ns.com/cdn-cgi/trace  | grep loc | cut -c 5-)
    else
      LOC=$(bashget http://cf-ns.com/cdn-cgi/trace  | grep loc | cut -c 5-)
    fi
  fi
}
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
function fastDebMirror () {
  ensureLoc
  if [ "$LOC" == CN ]; then
    [ $SEI_BACKUP ] && cp /etc/apt/sources.list ~/.seinit/sources.list
    if [ "$LSB" == "ubuntu" ]; then
      # sed -i 's#^deb [^ ]* #deb mirror://mirrors.ubuntu.com/mirrors.txt #g' /etc/apt/sources.list
      sed -i 's#/archive.ubuntu.com/#/mirrors.ustc.edu.cn/#g' /etc/apt/sources.list
    elif [ "$LSB" == "debian" ]; then
      sed -i 's#/deb.debian.org/#/mirrors.ustc.edu.cn/#g' /etc/apt/sources.list
    fi
  fi
}
function updatePMMetadata () {
  if [ $PM == "apt-get" ]; then
    fastDebMirror
    apt-get update
  elif [ $PM == "yum" ]; then
    yum makecache
  fi
}
function importSSHKeys () {
  [ -d ~/.ssh ] || mkdir ~/.ssh
  [ $SEI_BACKUP ] && cp -r ~/.ssh ~/.seinit/dot_ssh
  chmod 700 ~/.seinit/dot_ssh
  chmod 755 ~/.ssh
  mkdir -p /usr/local/bin
  wget -O /usr/local/bin/se-update-keys https://oott123.urn.cx/seinit/update-keys.sh
  chmod +x /usr/local/bin/se-update-keys
  /usr/local/bin/se-update-keys
  [ $SEI_BACKUP ] && (crontab -l || echo) > ~/.seinit/crontab
  (crontab -l || echo) | grep -v /usr/local/bin/se-update-keys | { cat; echo "3 5 * * * /usr/local/bin/se-update-keys"; } | crontab -
}
function installByobu () {
  installPackage byobu
  [ $SEI_BACKUP ] && cp /usr/share/byobu/profiles/tmux ~/.seinit/tmux
  echo "set-window-option -g allow-rename off" >> /usr/share/byobu/profiles/tmux
  sed -i 's/$BYOBU_DATE//' /usr/share/byobu/profiles/tmux
  mkdir -p "$HOME/.byobu"
  wget -O "$HOME/.byobu/status" https://oott123.urn.cx/seinit/byobustatus
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
  ensureLoc
  if [ "$LOC" == CN ]; then
    export REMOTE=https://git.atto.town/public-mirrors/oh-my-zsh.git
  fi
  curl https://git.atto.town/public-mirrors/oh-my-zsh/-/raw/master/tools/install.sh | grep -v 'env zsh' | bash
  [ $SEI_BACKUP ] && cp ~/.zshrc ~/.seinit/dot_zshrc
  sed -i 's/^ZSH_THEME=.*$/ZSH_THEME=ys/g' ~/.zshrc
  sed -i '/oh-my-zsh.sh/i DISABLE_AUTO_UPDATE=true' ~/.zshrc
}
function updateVimRc () {
  curl https://oott123.urn.cx/seinit/.vimrc > ~/.vimrc
}
function updateSystemVimRc() {
  echo "set mouse=" >> /etc/vim/vimrc.local
  echo "set ttymouse=" >> /etc/vim/vimrc.local
}
function help () {
  echo -e "# ${blue}installPackage${end} - Install package"
  echo -e "# ${blue}suckIPv6${end} - Disable IPv6"
  echo -e "# ${blue}updatePMMetadata${end} - Update package manager metadata"
  echo -e "# ${blue}importSSHKeys${end} - Import SSH keys"
  echo -e "# ${blue}installByobu${end} - Install byobu"
  echo -e "# ${blue}changeSSHPort 33${end} - Change SSH port to 33"
  echo -e "# ${blue}disableSSHRootLoginWithPassword${end} - Disable SSH root login with password"
  echo -e "# ${blue}enhanceSSHConnection${end} - Enable SSH TCPKeepAlive stuff"
  echo -e "# ${blue}restartSSHService${end} - Restart SSH server"
  echo -e "$ ${blue}installOmz${end} - Install Oh-my-zsh"
  echo -e "$ ${blue}updateVimRc${end} - Update .vimrc"
}

if [ "$SEI_SHELL" == "" ]; then
  # ...
  SEI_BACKUP=yes
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
    installPackageYumOnly epel-release
    installByobu
    installPackage zsh wget curl git htop ncdu vim rsync
    updateSystemVimRc
    if (which update-alternatives > /dev/null); then
      update-alternatives --set editor /usr/bin/vim.basic
    fi
    if [ -f /bin/zsh ]; then
      usermod -s /bin/zsh root
    fi
    importSSHKeys
    [ -f /etc/default/motd-news ] && sed -i 's/ENABLED=./ENABLED=0/' /etc/default/motd-news
    [ -d /etc/update-motd.d ] && chmod o-x,g-x,a-x /etc/update-motd.d/*
    installPackageAptOnly progress
    installPackageAptOnly software-properties-common || true
    installPackageAptOnly python-software-properties || true
    installOmz
    set +x
    echo "--- Seinit finish its work now. ---"
    echo "You'd better check authorized keys file and new SSH / firewall config"
    echo "to ensure you are not locked out before you close current session."
    echo "Wish you have a good day, bye!"
  else
    installOmz
  fi
elif [ "$SEI_SHELL" == "1" ]; then
  set +x
  set +e
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
  PS1="[\u@\h \[\033[41m\]SEI_SHELL\[\033[0m\]]\$> "
  clear
  echo ""
  help
  echo ""
  echo "Type [help] to see what you can do"
  echo "Type [exit] to exit sei shell"
  echo ""
  cd /tmp
fi
