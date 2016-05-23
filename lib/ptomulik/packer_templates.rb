require 'rake'
require 'rake/clean'

module PTomulik; end
module PTomulik::PackerTemplates
  extend Rake::DSL
  class << self

    def munge_dir(dir)
      (dir.empty? or dir.end_with?('/')) ? dir : "#{dir}/"
    end

    def self.define_defaults(args = {})
      args.map do |name,value|
        default = ('default_' + name.to_s).intern
        define_method(default) { value }
      end
    end

    def self.define_param(name, options={})
      default = ('default_' + name.to_s).intern
      define_method(name) do |args={}|
        pp = options[:postproc] ? method(options[:postproc]) : lambda {|val| val}
        pp.call(args[name] || send(default))
      end
    end

    define_defaults :systems    => ['freebsd']
    define_defaults :providers  => ['virtualbox']
    define_defaults :variants   => {
      'freebsd' => [ '', 'ports' ]
    }
    define_defaults :exclusions => [
      'freebsd-11.0-i386-ports',  # ports.txz is missing on CD
      'freebsd-11.0-amd64-ports'  # ports.txz is missing on CD
    ]
    define_defaults :boxfile_prefix     => 'packer_'
    define_defaults :boxfile_suffix     => '.box'
    define_defaults :varfile_prefix     => ''
    define_defaults :varfile_suffix     => '.json'
    define_defaults :sysfile_prefix     => ''
    define_defaults :sysfile_suffix     => '.json'
    define_defaults :vagrantfile_prefix => ''
    define_defaults :vagrantfile_suffix => '.rb'
    define_defaults :boxfile_dir        => ''
    define_defaults :varfiles_dir       => 'packer/variations/'
    define_defaults :sysfiles_dir       => 'packer/systems/'
    define_defaults :vagrantfiles_dir   => 'packer/vagrant/'

    define_param(:systems)
    define_param(:providers)
    define_param(:variants)
    define_param(:exclusions)
    define_param(:boxfile_prefix)
    define_param(:boxfile_suffix)
    define_param(:varfile_prefix)
    define_param(:varfile_suffix)
    define_param(:sysfile_prefix)
    define_param(:sysfile_suffix)
    define_param(:vagrantfile_prefix)
    define_param(:vagrantfile_suffix)
    define_param(:boxfile_dir, :postproc => :munge_dir)
    define_param(:varfiles_dir, :postproc => :munge_dir)
    define_param(:sysfiles_dir, :postproc => :munge_dir)
    define_param(:vagrantfiles_dir, :postproc => :munge_dir)

    def systems_regexp(args = {})
      /#{systems(args).map{|s| Regexp.escape s}.join('|')}/
    end

    def providers_regexp(args = {})
      providers(args).map{|s| Regexp.escape s}.join('|')
    end

    def ostuple_regexp(args={})
      /(?<system>#{systems_regexp(args)})-(?<version>[^-]+)-(?<arch>[^-]+)/
    end

    def builder_regexp(args={})
      /(?<ostuple>#{ostuple_regexp(args)})(?:-(?<variant>[^_]+))?/
    end

    def boxfile_regexp(args = {})
      suffix = Regexp.escape(boxfile_suffix(args))
      prefix = Regexp.escape(boxfile_prefix(args))
      dir = Regexp.escape(boxfile_dir(args))
      /(?<dir>#{dir})(?<prefix>#{prefix})(?<builder>#{builder_regexp(args)})_(?<provider>#{providers_regexp(args)})(?<suffix>#{suffix})/
    end

    def varfiles_regexp(args = {})
      dir = Regexp.escape(varfiles_dir(args))
      prefix = Regexp.escape(varfile_prefix(args)) 
      suffix = Regexp.escape(varfile_suffix(args)) 
      ostuple = /(?<system>#{systems_regexp(args)})-(?<version>[^-]+)-(?<arch>[^-]+)/
      /(?<dir>#{dir})(?<prefix>#{prefix})(?<builder>#{builder_regexp(args)})(?<suffix>#{suffix})/
    end

    def box_rule_target(args = {})
      /^#{boxfile_regexp(args)}$/
    end

    def boxfile_system(boxfile, args = {})
      re = /^#{boxfile_regexp(args)}$/
      boxfile.sub(re, '\k<system>')
    end

    def boxfile_builder(boxfile, args = {})
      re = /^#{boxfile_regexp(args)}$/
      boxfile.sub(re, '\k<builder>')
    end

    def boxfile_sysfile(boxfile, args = {})
      re = /^#{boxfile_regexp(args)}$/
      dir = sysfiles_dir(args)
      prefix = sysfile_prefix(args)
      suffix = sysfile_suffix(args)
      boxfile.sub(re, "#{dir}#{prefix}\\k<system>#{suffix}")
    end

    def boxfile_varfile(boxfile, args = {})
      re = /^#{boxfile_regexp(args)}$/
      dir = varfiles_dir(args)
      prefix = varfile_prefix(args)
      suffix = varfile_suffix(args)
      boxfile.sub(re, "#{dir}#{prefix}\\k<ostuple>#{suffix}")
    end

    def boxfile_vagrantfile(boxfile, args = {})
      re = /^#{boxfile_regexp(args)}$/
      dir = vagrantfiles_dir(args)
      prefix = vagrantfile_prefix(args)
      suffix = vagrantfile_suffix(args)
      boxfile.sub(re, "#{dir}#{prefix}\\k<system>#{suffix}")
    end

    def box_rule_sources(args = {})
      [
        proc { |boxfile| boxfile_sysfile(boxfile, args) },
        proc { |boxfile| boxfile_varfile(boxfile, args) },
        proc { |boxfile| boxfile_vagrantfile(boxfile, args) }
      ]
    end

    def box_rule(args = {})
      rule( box_rule_target(args) => box_rule_sources(args) ) do |t|
        name = t.name.sub(/^#{boxfile_regexp(args)}$/, '\k<builder>')
        sh "packer build -only '#{name}' -var-file='#{t.sources[1]}' '#{t.source}'"
      end
      CLOBBER.include( boxfiles )
    end

    def find_varfiles(args)
      Dir["#{varfiles_dir(args)}*.json"].select{ |x| x =~ /^#{varfiles_regexp}$/ }
    end

    def varfile_system(varfile, args={})
      varfile.sub(/^#{varfiles_regexp(args)}$/, '\k<system>')
    end

    def varfile_ostuple(varfile, args={})
      varfile.sub(/^#{varfiles_regexp(args)}$/, '\k<ostuple>')
    end

    def ostuple_builder(ostuple, variant, args={})
      variant.empty? ? ostuple : "#{ostuple}-#{variant}"
    end

    def varfile_builder(varfile, variant, args={})
      ostuple_builder(varfile_ostuple(varfile, args), variant, args)
    end

    def builder_boxfile(builder, provider, args={})
      dir     = boxfile_dir(args)
      prefix  = boxfile_prefix(args)
      suffix  = boxfile_suffix(args)
      "#{dir}#{prefix}#{builder}_#{provider}#{suffix}"
    end

    def varfile_boxfile(varfile, variant, provider, args={})
      builder_boxfile(varfile_builder(varfile, variant), provider, args)
    end

    def boxfiles(args = {})
      variants  = variants(args)
      providers = providers(args)
      boxfiles = []
      find_varfiles(args).map do |varfile|
        system = varfile_system(varfile, args)
        (variants[system] || []).uniq.map do |variant|
          builder = varfile_builder(varfile, variant, args)
          unless exclusions(args).include?(builder) then
            providers.map do |provider|
              unless exclusions(args).include?(builder + '_' + provider)
                boxfiles.push(builder_boxfile(builder, provider, args))
              end
            end
          end
        end
      end
      boxfiles
    end

    def box_tasks(args = {})
      variants  = variants(args)
      providers = providers(args)
      multitask :default
      find_varfiles(args).map do |varfile|
        system = varfile_system(varfile, args)
        desc "Generate boxes for #{system}"
        multitask system
        (variants[system] || []).uniq.map do |variant|
          builder = varfile_builder(varfile, variant, args)
          unless exclusions(args).include?(builder) then
            desc "Generate box for #{builder}"
            providers.map do |provider|
              unless exclusions(args).include?(builder + '_' + provider)
                task builder => builder_boxfile(builder, provider, args)
                multitask system => builder
              end
            end
          end
        end
        multitask :default => system
      end
    end
  end
end


def box_rule(*args)
  PTomulik::PackerTemplates.box_rule(*args)
end

def box_tasks(*args)
  PTomulik::PackerTemplates.box_tasks(*args)
end
