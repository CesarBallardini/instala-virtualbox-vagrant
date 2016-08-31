#!/bin/bash
# bin/instala-host-ubuntu-amd64.sh

# buscar paquete apropiado a arquitectura y cpu en https://www.vagrantup.com/downloads.html 
#
VAG_Version=1.8.1


# buscar paquete apropiado a arquitectura+cpu y que sea admitido por Vagrant en https://www.virtualbox.org/wiki/Downloads
# son dos:
#    1. VirtualBox platform package
#    2. VirtualBox Oracle VM VirtualBox Extension Pack
#

##
# info de la version del Virtualbox
VB_MayorVersion=5.0
VB_MinorVersion=26

##
# release number del Oracle Virtualbox Extension Pack
VB_EXTPACK_ReleaseNumber=108824

#######################################
##
# no hay mas cambios desde esta linea hacia abajo
#

##
# la distro donde se van a instalar los paquetes Virtualbox y Vagrant:
distro=`lsb_release -d | awk '{print $2}'`
release=`lsb_release -d | awk '{print $3}'`
codename=`lsb_release -c | awk '{print $2}'`
arch=`arch`

error() {
  echo $* >&2
  exit 1
}


oracle_pubkey() {

  if [ $codename == "trusty" -o $codename == "wheezy" ] ; then echo oracle_vbox.asc      ; return ; fi
  if [ $codename == "xenial" -o $codename == "jessie" ] ; then echo oracle_vbox_2016.asc ; return ; fi

  error "no se puede determinar cual es la clave de APT de Oracle para distro:"${distro}" y codename: "${codename}
}


instalo_virtualbox() {

  # verifico si no esta ya instalado
  dpkg -l  virtualbox-${VB_MayorVersion} >/dev/null ; VB_INSTALADO=$?
  if [ 0 -ne "${VB_INSTALADO}" ] ; then
    Oracle_pubkey_filename=`oracle_pubkey`

    # fuente de paquetes de Oracle para Virtualbox
    sudo bash -c "echo 'deb http://download.virtualbox.org/virtualbox/debian '${codename}' contrib' > /etc/apt/sources.list.d/virtualbox.list"

    # The Oracle public key for apt-secure:
    wget -q https://www.virtualbox.org/download/${Oracle_pubkey_filename} -O- | sudo apt-key add - 

    # actualizo lista de paquetes
    sudo apt-get update

    # instalo Virtualbox y dkms to ensure that the VirtualBox host kernel modules (vboxdrv, vboxnetflt and vboxnetadp) are properly updated if the linux kernel version changes during the next apt-get upgrade. 
    sudo apt-get install -y --force-yes virtualbox-${VB_MayorVersion} dkms ; ret=$?
    [ 0 -eq "$ret" ] || error "no se pudo instalar dkms y "virtualbox-${VB_MayorVersion}
    
  fi
}


instalo_oracle_extension_pack() {

  VB_BASE_URL=http://download.virtualbox.org/virtualbox/${VB_MayorVersion}.${VB_MinorVersion}
  VB_EXTPACK_FILENAME=Oracle_VM_VirtualBox_Extension_Pack-${VB_MayorVersion}.${VB_MinorVersion}-${VB_EXTPACK_ReleaseNumber}.vbox-extpack

  # verifico si no esta ya instalado
  if [ 0 -eq `sudo VBoxManage list extpacks | awk '/Extension Packs:/ {print $3} '` ] ; then
    [ -r ${VB_EXTPACK_FILENAME} ] || wget -q ${VB_BASE_URL}/${VB_EXTPACK_FILENAME} ; ret=$?
    [ 0 -eq "$ret" ] || error "no se pudo descargar el extension pack: "${VB_BASE_URL}/${VB_EXTPACK_FILENAME}

    # instalo el Extension Pack
    sudo VBoxManage extpack install ${VB_EXTPACK_FILENAME} 2>/dev/null ; ret=$?
    [ 0 -eq "$ret" ] || error "no se pudo instalar el extension pack: "${VB_EXTPACK_FILENAME}

    #sudo VBoxManage list extpacks
    #sudo VBoxManage extpack uninstall "Oracle VM VirtualBox Extension Pack"
  fi

}


instalo_vagrant() {
  VAG_BASE_URL=https://releases.hashicorp.com/vagrant/${VAG_Version}
  VAG_PKG_NAME=vagrant_${VAG_Version}_${arch}.deb

  # verifico si no esta ya instalado
  dpkg -l vagrant >/dev/null ; VAG_INSTALADO=$?
  if [ 0 -ne "${VAG_INSTALADO}" ] ; then

    [ -r ${VAG_PKG_NAME} ] || wget -q ${VAG_BASE_URL}/${VAG_PKG_NAME} ; ret=$?
    [ 0 -eq "$ret" ] || error "no se pudo descargar vagrant: "${VAG_BASE_URL}/${VAG_PKG_NAME}

    sudo dpkg -i ${VAG_PKG_NAME} ; ret=$?
    [ 0 -eq "$ret" ] || error "no se pudo instalar "${VAG_PKG_NAME}
  fi

}

instalo_vagrant_proxyconf() {
  vagrant plugin install vagrant-proxyconf

  cat > ~/.vagrant.d/Vagrantfile << !EOF
Vagrant.configure("2") do |config|
  puts "proxyconf..."
  if Vagrant.has_plugin?("vagrant-proxyconf")
    puts "find proxyconf plugin !"
    if ENV["http_proxy"]
      puts "http_proxy: " + ENV["http_proxy"]
      config.proxy.http     = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      puts "https_proxy: " + ENV["https_proxy"]
      config.proxy.https    = ENV["https_proxy"]
    end
    if ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"]
    end
  end
end
!EOF
}

instalo_vagrant_plugins() {
  mkdir -p ~/.vagrant.d/

  instalo_vagrant_proxyconf
  vagrant plugin install vagrant-share
  vagrant plugin install vagrant-vbguest
}


##
# main
#
instalo_virtualbox
instalo_oracle_extension_pack

instalo_vagrant
instalo_vagrant_plugins

##
# luego se puede verificar la instalacion con:
#
# vagrant init ubuntu/trusty32; vagrant up # para crear una VM de prueba
# vagrant ssh     # para conectarte a la VM recien creada

