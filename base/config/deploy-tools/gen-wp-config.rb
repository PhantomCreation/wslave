require 'erb'
require 'yaml'
require 'ostruct'

def GenerateWPConfig(profile = 'production', out_path = './')
  require_relative 'gen-salts' # Generate salts if necessary

  config_path = File.dirname(File.expand_path(File.dirname(__FILE__)))
  vars = {}
  vars[:profile] = profile.to_sym
  vars[:db_info] = YAML.load_file("#{config_path}/database.yml", aliases: true)
  vars[:salt] = YAML.load_file("#{config_path}/salts.yml", aliases: true)

  erb_source = File.read("#{config_path}/deploy-tools/wp-config.php.erb")
  rend = ERB.new(erb_source)
  res = rend.result(OpenStruct.new(vars).instance_eval { binding })
  File.write("#{out_path}/wp-config.php", res)
end
