#!/bin/bash
set -e
set -x

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
      LOC=$(curl -s http://su.baidu.com/cdn-cgi/trace | grep loc | cut -c 5-)
    elif (which wget > /dev/null); then
      LOC=$(wget -O- http://su.baidu.com/cdn-cgi/trace  | grep loc | cut -c 5-)
    else
      echo "You don't have curl or wget installed. Use LOC=CN seinit.sh to init, or install curl or wget to continue!"
      exit 1
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
  wget -O /usr/local/bin/se-update-keys https://raw.githubusercontent.com/oott123/seinit/master/update-keys.sh
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
  wget -O "$HOME/.byobu/status" https://raw.githubusercontent.com/oott123/seinit/master/byobustatus
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
  curl https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | grep -v 'env zsh' | bash
  [ $SEI_BACKUP ] && cp ~/.zshrc ~/.seinit/dot_zshrc
  sed -i 's/^ZSH_THEME=.*$/ZSH_THEME=ys/g' ~/.zshrc
}
function updateVimRc () {
  if [ $SEI_BACKUP ]; then
    [ -e ~/.vimrc ] || mv ~/.vimrc ~/.seinit/vimrc
  fi
  curl https://raw.githubusercontent.com/oott123/dotfiles/master/.vimrc > ~/.vimrc
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
    installPackageYumOnly epel-release
    installByobu
    installPackage zsh wget curl git htop ncdu vim
    if (which update-alternatives > /dev/null); then
      update-alternatives --set editor /usr/bin/vim.basic
    fi
    if [ -f /bin/zsh ]; then
      usermod -s /bin/zsh root
    fi
    importSSHKeys
    [ -f /etc/default/motd-news ] && sed -i 's/ENABLED=./ENABLED=0/' /etc/default/motd-news
    [ -d /etc/update-motd.d ] && chmod -x /etc/update-motd.d/*
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
