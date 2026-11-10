Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "node01" do |node01|
    node01.vm.hostname = "node01"

    node01.vm.provider "vmware_desktop" do |vmware|
      vmware.memory = 2048
      vmware.cpus = 2
      vmware.force_vmware_license = "professional"
    end
  end

  config.vm.define "node02" do |node02|
    node02.vm.hostname = "node02"

    node02.vm.provider "vmware_desktop" do |vmware|
      vmware.memory = 2048
      vmware.cpus = 2
      vmware.force_vmware_license = "professional"
    end
  end

end
