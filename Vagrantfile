VAGRANTFILE_API_VERSION = "2"

#arch= "i386"    ; bits="32" ; distro="ubuntu" ; codename="trusty"
#arch= "x86_64" ; bits="64" ; distro="ubuntu" ; codename="trusty"

#arch= "i386"   ; bits="32" ; distro="ubuntu" ; codename="xenial"
#arch= "x86_64" ; bits="64" ; distro="ubuntu" ; codename="xenial"

##
# Debian en 32 bits no esta disponible en Atlas
##

#arch= "x86_64" ; bits="64" ; distro="debian" ; codename="wheezy"
arch= "x86_64" ; bits="64" ; distro="debian" ; codename="jessie"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "vagranthost"+bits do |base|
    base.vm.box = distro+"/"+codename+bits
    #base.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/"+codename+"/current/"+codename+"-server-cloudimg-"+arch+"-vagrant-disk1.box"
    base.vm.hostname = "noc.dev"
    base.vm.provision "shell", path: "provision/os-setup.sh", privileged: true
    base.vm.provision "shell", path: "provision/instala-virtualbox-vagrant.sh", privileged: false
    base.vm.network "private_network", ip: "192.168.33.100"
    base.ssh.forward_agent = true
    base.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--nictype1", "Am79C973"]
      vb.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
      vb.customize ["modifyvm", :id, "--memory", 512]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.gui = false
      vb.name = "Vagrant host "+codename+" "+arch
      vb.memory = "512"
    end
  end
end


