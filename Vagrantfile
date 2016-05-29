# -*- mode: ruby -*-
# vi: set ft=ruby :

# https://gist.github.com/leifg/4713995
  class VagrantPlugins::ProviderVirtualBox::Action::SetName
    alias_method :original_call, :call
    def call(env)
      machine = env[:machine]
      driver = machine.provider.driver
      uuid = driver.instance_eval { @uuid }
      ui = env[:ui]

      controller_name = 'SATAController'

      vm_info = driver.execute("showvminfo", uuid)
      has_this_controller = vm_info.match("Storage Controller Name.*#{controller_name}")

      if has_this_controller
        ui.info "already has the #{controller_name} hdd controller"
      else
        ui.info "creating #{controller_name} controller #{controller_name}"
        driver.execute('storagectl', uuid,
          '--name', "#{controller_name}",
          '--add', 'sata',
          '--controller', 'IntelAhci')
      end

      ## Disk Management
      format = "VMDK"
      size = 1024
      port = 0

      ui.info "attaching storage to #{controller_name}"
      %w(sdb sdc sdd).each do |hdd|
        if File.exist?("#{hdd}" + ".vmdk")
          ui.info "#{hdd} Already Exists"
        else
              ui.info "Creating #{hdd}\.vmdk"
              driver.execute("createhd", 
                   "--filename", "#{hdd}", 
                   "--size", size.to_s, 
                   "--format", "#{format}")
               end

        # Attach devices
        driver.execute('storageattach', uuid,
          '--storagectl', "#{controller_name}",
          '--port', (port += 1).to_s,
          '--type', 'hdd',
          '--medium', "#{hdd}" + ".vmdk")
      end

      original_call(env)
    end
  end

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
  config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

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
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
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
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y mdadm
    sudo apt-get install -y lvm2
    # put some data in nova's catalog (for testing purposes only)
    sudo mkdir -p /var/lib/nova/instances
    sudo touch /var/lib/nova/instances/test{1,2,3}
    # add nova user and group
    sudo groupadd nova
    sudo useradd -g nova nova
  SHELL
end
