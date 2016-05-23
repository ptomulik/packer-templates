# vim: ft=ruby:

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'lib'))
require 'ptomulik/packer_templates'
require 'rake'

#
# How different systems are being configured
#

def freebsd(cfg, boxfile, boxname)
  cfg.ssh.shell   = 'sh'
  cfg.vm.guest    = :freebsd
  cfg.vm.box      = "ptomulik/#{boxname}"
  cfg.vm.box_url  =  "file:///#{File.dirname(__FILE__)}/#{boxfile}"
end

#
# Driver...
#
Vagrant.configure(2) do |config|
  builders = []
  PTomulik::PackerTemplates.boxfiles.map do |boxfile|
    system = PTomulik::PackerTemplates.boxfile_system(boxfile)
    boxname = PTomulik::PackerTemplates.boxfile_builder(boxfile)
    config.vm.define boxname, autostart: false do |cfg|
      send(system.intern, cfg, boxfile, boxname)
    end
    builders.push(boxname)
  end

  # Present machines that may be used...
  if ARGV.include?('up') then
    i = ARGV.index('up')
    unless ARGV.size > i+1 and builders.include?(ARGV[-1]) then
      puts("No default machine defined, use one of the following:")
      builders.map do |name|
        puts("vagrant up #{name}\n")
      end
    end
  end
end

