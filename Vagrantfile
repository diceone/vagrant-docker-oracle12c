# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # copied directly from vagrant init chef/centos-6.5
  config.vm.box = "chef/centos-6.5"

  # change memory size
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
  end

  # run setup.sh
  config.vm.provision "shell", path: "setup.sh"
end
