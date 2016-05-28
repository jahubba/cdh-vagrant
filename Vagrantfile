# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "centos/7"
  config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
  config.vm.provision "file", source: "eagle5-deployment.json", destination: "/tmp/eagle5-deployment.json"
  config.vm.provision "file", source: "id_rsa", destination: "/tmp/id_rsa"
  config.vm.provision "file", source: "id_rsa.pub", destination: "/tmp/id_rsa.pub"
  config.vm.provision "file", source: "xd.patch", destination: "/tmp/xd.patch"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.provision :shell, path: "cm-setup.sh"
  # Disable static rsync and force virtualbox shared folder
  config.vm.synced_folder ".", "/home/vagrant/sync", disabled: true
  config.vm.synced_folder "..", "/opt/workspace"
  #config.vm.provision "docker" do |d|
  #  d.run "rabbitmq"
  #  d.run "redis"
  #  d.run "zookeeper", image: "springxd/zookeeper:1.1.0"
  #  d.run "hsqldb", image: "springxd/hsqldb:1.1.0"
  #  d.run "admin", image: "springxd/admin:1.1.0", args: "--link zookeeper:zookeeper --link hsqldb:hsqldb --link redis:redis -p 9393:9393"
  #  d.run "container", image: "springxd/container:1.1.0", args: "--link zookeeper:zookeeper --link hsqldb:hsqldb --link redis:redis"
  #  d.pull_images "springxd/shell:1.1.0"
  #end
  if Vagrant.has_plugin?("vagrant-proxyconf")
    if ENV["http_proxy"]
      config.proxy.http     = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      config.proxy.https    = ENV["https_proxy"]
    end
    if ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"]
	else
	  config.proxy.no_proxy = "localhost,127.0.0.1"
    end
  end

  config.vm.hostname = "megamaid"
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 9393, host: 9393
  config.vm.network "forwarded_port", guest: 7180, host: 7180
  config.vm.network "forwarded_port", guest: 8888, host: 8888
  config.vm.network "forwarded_port", guest: 8088, host: 8088
  config.vm.network "forwarded_port", guest: 15672, host: 15672
  config.vm.network "forwarded_port", guest: 9393, host: 9393
  config.vm.network "forwarded_port", guest: 1045, host: 1045

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  # Add disk for swap
    file_to_disk = File.join(File.dirname(File.expand_path(__FILE__)), "/swapdisk.vdi")
    if ARGV[0] == "up" && ! File.exist?(file_to_disk) 
      puts "Creating 8GB disk #{file_to_disk}."
      vb.customize [
        'createhd', 
        '--filename', file_to_disk, 
        '--format', 'VDI', 
        '--size', 9 * 1024
      ] 
      vb.customize [
        'storageattach', :id, 
        '--storagectl', 'IDE Controller', 
        '--port', 1, '--device', 0, 
        '--type', 'hdd', '--medium', 
        file_to_disk
      ]
    end
  # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  #
  # Customize the amount of memory on the VM:
    vb.memory = "4096"
	vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional', '--draganddrop', 'bidirectional']
   end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
