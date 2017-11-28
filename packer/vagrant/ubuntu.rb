Vagrant.require_version '>= 1.1.0'

Vagrant.configure("2") do |config|
  config.ssh.shell = 'sh'
  config.vm.synced_folder '.', '/vagrant', disabled: true
end
