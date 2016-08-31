#!/bin/bash
#
##
# provision/os-setup.sh
# instala lo necesario a nivel de sistema operativo
#

# vm_swapfilesize: si esta vacio no se crea area de swap en la VM
vm_swapfilesize=2G


#######################################################
##
# no hay mas que modificar desde esta linea hacia abajo
##

source /vagrant/provision/private/setup.sh

distro=`lsb_release -d | awk '{print $2}'`
codename=`lsb_release -c | awk '{print $2}'`

aseguro_config_apt() {
  [ -n "$(type -t aseguro_sources_list)" ] && [ "$(type -t aseguro_sources_list)" = function ] && aseguro_sources_list ${distro} ${codename}
  apt-get    update
}

actualizo_paquetes_sistema() {
  apt-get    update
  apt-get -y upgrade
  apt-get -y autoremove
  apt-get -y dist-upgrade
  apt-get -y --force-yes autoremove
  apt-get -y autoclean
}

aseguro_un_minimo_espacio_de_swap() {
  vm_swapfilesize=$1

  if [ -n "${vm_swapfilesize}" ]
  then
    fallocate -l ${vm_swapfilesize} /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    # swapon -s  # verificar que el swap funciona
    echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab
  fi
}


mejoras_en_performance() {
  sysctl vm.swappiness=10
  echo 'vm.swappiness=10' > /etc/sysctl.conf

  sysctl vm.vfs_cache_pressure=50
  echo 'vm.vfs_cache_pressure = 50' > /etc/sysctl.conf
}

instalo_keyring() {
  [ $distro == "Debian" ] && apt-get install -y debian-keyring
  [ $distro == "Ubuntu" ] && apt-get install -y --force-yes ubuntu-keyring ubuntu-extras-keyring
}

instalo_paquetes_esenciales() {
  apt-get install -y --force-yes debconf-utils
  apt-get install -y --force-yes python-software-properties build-essential
  apt-get install -y --force-yes git
}

###################################
##
# main
#
aseguro_config_apt
aseguro_un_minimo_espacio_de_swap ${vm_swapfilesize}
mejoras_en_performance

instalo_keyring
instalo_paquetes_esenciales
actualizo_paquetes_sistema
# EOF

