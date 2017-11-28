module PTomulik; module PackerTemplates; end; end

#
# Boxfile syntax:
#
#   boxfile   := <dir><prefix><boxname><suffix>
#   boxname   := <basename>_<provider>
#   name      := <ostuple>(-<variant>)?
#   ostuple   := <system>-<version>-<arch>
#   provider  := "virtualbox" | "vmware_workstation" | ....
#   system    := "freebsd" | "ubuntu" | ...
#
# Varfile syntax:
#
#   varfile   := <dir><prefix><ostuple><suffix>
#
module PTomulik::PackerTemplates::Util

  class << self

    def munge_dir(dir)
      (dir.empty? or dir.end_with?('/')) ? dir : "#{dir}/"
    end

    # Defines a method which returns default value for a named parameter
    #
    # Example:
    #
    #   define_default :param1, value1,
    #   define_default :param2, value2
    #
    # This shall define the following methods:
    #
    #   def default_param1; value1; end
    #   def default_param2; value2; end
    #
    def self.define_default(name, value, args = {})
      default = ('default_' + name.to_s).intern
      define_method(default) { value }
    end

    # Define a method which returns value of a named parameter
    #
    # Example:
    #
    #   define_param  :param1
    #   define_param  :param2, :postproc => :munge_dir
    #
    # This shall generate following methods:
    #
    #   param1(args = {})
    #   param2(args = {})
    #
    # - param1 returns default_param1
    # - param2 returns munge_dir(default_param2),
    # - param1(:param1 => 'foo') returns 'foo',
    # - param2(:param2 => 'bar') return munge_dir('bar').
    #
    def self.define_param(name, options={})
      default = ('default_' + name.to_s).intern
      unless options[:default].nil?
        define_default name, options[:default], options
      end
      define_method(name) do |args={}|
        pp = options[:postproc] ? method(options[:postproc]) : lambda {|val| val}
        pp.call(args[name] || send(default))
      end
    end

    @default_providers = []

    # Discover what providers are available....
    begin
      $VMWARE_VERSION ||= `vmware --version`
    rescue
      $VMWARE_VERSION = ""
    end

    begin
      $VIRTUALBOX_VERSION ||= `vboxmanage --version`
    rescue
      $VIRTUALBOX_VERSION = ""
    end

    @default_providers.push('virtualbox') unless $VIRTUALBOX_VERSION.empty?
    @default_providers.push('vmware_workstation') if $VMWARE_VERSION =~ /VMware Workstation/i

    define_param :systems,            :default => ['freebsd', 'ubuntu']
    define_param :providers,          :default => @default_providers
    define_param :variants,           :default => { 'freebsd' => [ '', 'ports' ],
                                                    'ubuntu'  => ['slapd'] }
    define_param :exclusions,         :default => [ ]
    define_param :boxfile_prefix,     :default => 'packer_'
    define_param :boxfile_suffix,     :default => '.box'
    define_param :varfile_prefix,     :default => ''
    define_param :varfile_suffix,     :default => '.json'
    define_param :sysfile_prefix,     :default => ''
    define_param :sysfile_suffix,     :default => '.json'
    define_param :vagrantfile_prefix, :default => ''
    define_param :vagrantfile_suffix, :default => '.rb'
    define_param :outdir_prefix,      :default => 'output-'
    define_param :outdir_suffix,      :default => ''
    define_param :boxfile_dir,        :default => '',                   :postproc => :munge_dir
    define_param :varfiles_dir,       :default => 'packer/variants/',   :postproc => :munge_dir
    define_param :sysfiles_dir,       :default => 'packer/systems/',    :postproc => :munge_dir
    define_param :vagrantfiles_dir,   :default => 'packer/vagrant/',    :postproc => :munge_dir
    define_param :outdir_dir,         :default => '',                   :postproc => :munge_dir

    # Returns regular expression to match operating system names we support
    def systems_regexp(args = {})
      /#{systems(args).map{|s| Regexp.escape s}.join('|')}/
    end

    def providers_regexp(args = {})
      providers(args).map{|s| Regexp.escape s}.join('|')
    end

    def ostuple_regexp(args={})
      /(?<system>#{systems_regexp(args)})-(?<version>[^-]+)-(?<arch>[^_-]+)/
    end

    def name_regexp(args={})
      /(?<ostuple>#{ostuple_regexp(args)})(?:-(?<variant>[^_]+))?/
    end

    def boxname_regexp(args={})
      /(?<name>#{name_regexp(args)})_(?<provider>#{providers_regexp(args)})/
    end

    def boxfile_regexp(args = {})
      dir = Regexp.escape(boxfile_dir(args))
      suffix = Regexp.escape(boxfile_suffix(args))
      prefix = Regexp.escape(boxfile_prefix(args))
      /(?<dir>#{dir})(?<prefix>#{prefix})(?<boxname>#{boxname_regexp(args)})(?<suffix>#{suffix})/
    end

    def varfile_regexp(args = {})
      dir = Regexp.escape(varfiles_dir(args))
      prefix = Regexp.escape(varfile_prefix(args))
      suffix = Regexp.escape(varfile_suffix(args))
      /(?<dir>#{dir})(?<prefix>#{prefix})(?<ostuple>#{ostuple_regexp(args)})(?<suffix>#{suffix})/
    end

    def boxrule_target(args = {})
      /^#{boxfile_regexp(args)}$/
    end

    def self.define_substring(of,name)
      m1 = (name.to_s + '_in_' + of.to_s).intern
      m2 = (of.to_s + '_regexp').intern
      define_method(m1) do |str,args={}|
        str.sub(/^#{send(m2,args)}$/, "\\k<#{name}>")
      end
    end

    define_substring :boxfile, :dir
    define_substring :boxfile, :prefix
    define_substring :boxfile, :suffix
    define_substring :boxfile, :boxname
    define_substring :boxfile, :name
    define_substring :boxfile, :provider
    define_substring :boxfile, :ostuple
    define_substring :boxfile, :variant
    define_substring :boxfile, :system
    define_substring :boxfile, :version
    define_substring :boxfile, :arch

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

    def boxrule_sources(args = {})
      [
        proc { |boxfile| boxfile_sysfile(boxfile, args) },
        proc { |boxfile| boxfile_varfile(boxfile, args) },
        proc { |boxfile| boxfile_vagrantfile(boxfile, args) }
      ]
    end

    def find_varfiles(args)
      Dir["#{varfiles_dir(args)}*.json"].select{ |x| x =~ /^#{varfile_regexp}$/ }
    end

    define_substring :varfile, :system
    define_substring :varfile, :version
    define_substring :varfile, :arch
    define_substring :varfile, :ostuple

    def varfile_name(varfile, variant, args={})
      ostuple_name(ostuple_in_varfile(varfile, args), variant)
    end

    def ostuple_name(ostuple, variant, args={})
      variant.empty? ? ostuple : "#{ostuple}-#{variant}"
    end

    def ostuple_boxname(ostuple, variant, provider, args={})
      "#{ostuple_name(ostuple, variant, args)}_#{provider}"
    end

    def varfile_boxname(varfile, variant, provider, args={})
      ostuple_boxname(ostuple_in_varfile(varfile, args), variant, provider, args)
    end

    def boxname_boxfile(boxname, args={})
      dir     = boxfile_dir(args)
      prefix  = boxfile_prefix(args)
      suffix  = boxfile_suffix(args)
      "#{dir}#{prefix}#{boxname}#{suffix}"
    end

    def boxname_outdir(boxname, args={})
      dir     = outdir_dir(args)
      prefix  = outdir_prefix(args)
      suffix  = outdir_suffix(args)
      "#{dir}#{prefix}#{boxname}#{suffix}"
    end

    def name_boxname(name, provider, args={})
      "#{name}_#{provider}"
    end

    def varfile_boxfile(varfile, variant, provider, args={})
      boxname_boxfile(varfile_boxname(varfile, variant), provider, args)
    end

    def boxnames(args = {})
      boxnames = []
      variants = variants(args)
      providers = providers(args)
      find_varfiles(args).map do |varfile|
        system = system_in_varfile(varfile, args)
        (variants[system] || []).uniq.map do |variant|
          name = varfile_name(varfile, variant, args)
          unless exclusions(args).include?(name) then
            providers.map do |provider|
              boxname = name_boxname(name, provider, args)
              unless exclusions(args).include?(boxname)
                boxnames.push(boxname)
              end
            end
          end
        end
      end
      boxnames
    end

    def outdirs(args = {})
      boxnames(args).map{ |boxname| boxname_outdir(boxname, args) }
    end

    def boxfiles(args = {})
      boxnames(args).map{ |boxname| boxname_boxfile(boxname, args) }
    end
  end
end

module PTomulik::PackerTemplates::Util::DSL
  def self.publish_methods(*names)
    names.map do |name|
      define_method name do |*args|
        PTomulik::PackerTemplates::Util.send(name, *args)
      end
    end
  end

  publish_methods :boxnames, :outdirs, :boxfiles
  publish_methods :dir_in_boxfile, :prefix_in_boxfile, :suffix_in_boxfile,
                  :boxname_in_boxfile, :name_in_boxfile,
                  :provider_in_boxfile, :ostuple_in_boxfile,
                  :variant_in_boxfile, :system_in_boxfile,
                  :version_in_boxfile, :arch_in_boxfile
  publish_methods :system_in_varfile, :version_in_varfile, :arch_in_varfile,
                  :ostuple_in_varfile
end
