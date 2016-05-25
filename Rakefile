require 'rake/clean'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'lib'))
require 'ptomulik/packer_templates'


# This simply generates a rule for creating boxes from sources
boxrule

# Generate tasks which make particular boxes
boxtasks

task :default do
  sh %{rake -T}
end
