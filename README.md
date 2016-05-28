# SDS Development VM
## Setup
* Install VirtualBox http://www.virtualbox.org/wiki/Downloads
* Install Vagrant http://www.vagrantup.com/downloads
* Add settings to bash profile (~/.bash_profile)
    export VAGRANT_DETECTED_OS=cygwin # If running vagrant in cygwin 
    export http_proxy=http://<user>:<password>@c<proxyserver>/ # Proxy info for vagrant and virtual host
    export https_proxy=http://<user>:<password>@<proxyserver>/
* Add proxy plugin
    vagrant plugin install vagrant-proxyconf
* Add share plugin
    vagrant plugin install vagrant-share
* Add VirtualBox guest additions plugin
    vagrant plugin install vagrant-vbguest (0.11.0)
* Provision VM
    vagrant up (THIS WILL FAIL ON THE MOUNT COMMAND AND THAT'S OK)
    vagrant provision 
    vagrant reload
## Using
* Start the VM
    vagrant up
* Restart the VM
    vagrant reload
* Stop the VM
    vagrant halt
* Delete the VM
    vagrant destroy
* Passwordless ssh to VM
    vagrant ssh
* Default settings starts UI, you can login with username: vagrant, password: vagrant
* startx will start GNOME within VM
* WebUI ports have been opened and can be accessed in host web browser
 * Cloudera Manager http://localhost:7180/
 * HUE http://localhost:8888/
 * Spring XD http://localhost:9393/
 * RabbitMQ http://localhost:15672/
 * Resource Manager http://localhost:8088/
 * Java Debug on port 1045
