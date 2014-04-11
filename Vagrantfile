Vagrant.configure("2") do |config|
  config.vm.box = "precise32"
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.provision :shell, :path => "provision.sh"
end
