require 'rake'
require 'rake/clean'
require 'ptomulik/packer_templates/util'

module PTomulik::PackerTemplates::RakeTasks
  extend Rake::DSL

  class << self

    U = PTomulik::PackerTemplates::Util
    private_constant :U

    def boxrule(args = {})
      rule( U.boxrule_target(args) => U.boxrule_sources(args) ) do |t|
        name = t.name.sub(/^#{U.boxfile_regexp(args)}$/, '\k<boxname>')
        pp_filters = []
        filter = ''
        unless ENV['VAGRANTCLOUD_TOKEN'] and ENV['VAGRANTCLOUD_USER'] and (not ENV['VAGRANTCLOUD_DISABLE'] =~ /(yes|true|1)/i)
          # filter-out vagrant-cloud post-processors from template
          pp_filters << '.type!="vagrant-cloud"'
        end
        unless ENV['DOCKER_USER'] and (not ENV['DOCKER_IMPORT_DISABLE'] =~ /(yes|true|1)/i)
          # filter-out docker-import post-processors from template
          pp_filters << '.type!="docker-import"'
        end
        unless ENV['DOCKER_PASSWORD'] and ENV['DOCKER_USER'] and (not ENV['DOCKER_PUSH_DISABLE'] =~ /(yes|true|1)/i)
          # filter-out docker-push post-processors from template
          pp_filters << '.type!="docker-push"'
        end
        if pp_filters
          filter += " .[\"post-processors\"][0] |= map(select(#{pp_filters.join(' and ')}))"
        end
        sh "(jq '#{filter}' '#{t.source}' | packer build -only '#{name}' -var-file='#{t.sources[1]}' -)"
        #sh "packer build -only '#{name}' -var-file='#{t.sources[1]}' '#{t.source}'"
      end
      CLEAN.include( U.outdirs )
      CLOBBER.include( U.boxfiles )
    end

    def boxtasks(args = {})
      variants  = U.variants(args)
      providers = U.providers(args)
      U.find_varfiles(args).map do |varfile|
        system = U.system_in_varfile(varfile, args)
        version = U.version_in_varfile(varfile, args)
        arch = U.arch_in_varfile(varfile, args)
        desc "Generate all #{system} boxes"
        multitask system
        desc "Generate all #{system}-#{version}-* boxes"
        multitask "#{system}-#{version}"
        desc "Generate all #{system}-*-#{arch}* boxes"
        multitask "#{system}-#{arch}"
        desc "Generate all #{system}-#{version}-#{arch}* boxes"
        multitask "#{system}-#{version}-#{arch}*"
        (variants[system] || []).uniq.map do |variant|
          name = U.varfile_name(varfile, variant, args)
          boxnames = []
          unless U.exclusions(args).include?(name) then
            multitask system => name
            multitask "#{system}-#{version}" => name
            multitask "#{system}-#{arch}" => name
            multitask "#{system}-#{version}-#{arch}*" => name
            providers.map do |provider|
              boxname = U.name_boxname(name, provider, args)
              unless U.exclusions(args).include?(boxname)
                desc "Generate box for #{boxname}"
                task boxname => U.boxname_boxfile(boxname, args)
                boxnames.push(boxname)
              end
            end
          end
          unless boxnames.empty?
            es = (boxnames.size > 1) ? 'es' : ''
            desc "Generate box#{es} for #{boxnames.join(', ')}"
            multitask name => boxnames
          end
        end
      end
    end
  end
end

module PTomulik::PackerTemplates::RakeTasks::DSL
  def self.publish_methods(*names)
    names.map do |name|
      define_method name do |*args|
        PTomulik::PackerTemplates::RakeTasks.send(name, *args)
      end
    end
  end

  publish_methods :boxrule, :boxtasks
end

include PTomulik::PackerTemplates::RakeTasks::DSL
