# vim: ft=ruby:

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'lib'))
require 'ptomulik/packer_templates/util'
include PTomulik::PackerTemplates::Util::DSL

#
# How different systems are being configured
#
def common(cfg, boxfile, args={})
  cfg.ssh.shell   = 'sh'
  cfg.vm.box      = "#{boxname_in_boxfile(boxfile, args)}"
  cfg.vm.box_url  = "file://#{File.dirname(__FILE__)}/#{boxfile}"
end

def freebsd(cfg, boxfile, args={})
  cfg.vm.guest    = :freebsd
  common(cfg, boxfile, args)
end

def ubuntu(cfg, boxfile, args={})
  cfg.vm.guest    = :ubuntu
  common(cfg, boxfile, args)
end

#
# Driver...
#
Vagrant.configure("2") do |config|
  args = {}
  boxes = []
  boxfiles(args).map do |boxfile|
    system = system_in_boxfile(boxfile, args)
    boxname = boxname_in_boxfile(boxfile, args)
    config.vm.define boxname, autostart: false do |cfg|
      send(system.intern, cfg, boxfile, args)
    end
    boxes.push(boxname)
  end

  # Present machines that may be used...
  if ARGV.include?('up') then
    i = ARGV.index('up')
    unless ARGV.size > i+1 and boxes.include?(ARGV[-1]) then
      puts("No default machine defined, use one of the following:")
      boxes.map do |name|
        puts("vagrant up #{name}\n")
      end
    end
  end
end

