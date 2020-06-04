# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.provision :shell, privileged: true, path: "bootstrap.sh"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    
    vb.cpus = 2
    vb.memory = "2048"
  end
  
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/xenial64"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.10.10"
    master.vm.provision :shell, privileged: false, path: "bootstrap_master.sh"
  end

  config.vm.define "node-1" do |node1|
    node1.vm.box = "ubuntu/xenial64"
    node1.vm.hostname = "node-1"
    node1.vm.network "private_network", ip: "192.168.10.11"
    node1.vm.provision :shell, privileged: false, inline: <<-SHELL
      sudo /vagrant/join.sh
      sudo systemctl daemon-reload
      sudo systemctl restart kubelet
    SHELL
  end
end