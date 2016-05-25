Vagrant.require_version '>= 1.1.0'

Vagrant.configure(2) do |config|
  config.ssh.shell = 'sh'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provider 'virtualbox' do |vb, override|
    override.vm.base_mac =  'D8F7813EC212'
  end
end
