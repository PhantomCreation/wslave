require 'erb'
require 'yaml'
require 'ostruct'

def generate_wp_config(profile = 'production', out_path = './')
  require_relative 'gen_salts' # Generate salts if necessary

  config_path = File.dirname(__dir__)
  vars = {}
  vars[:profile] = profile.to_sym
  vars[:db_info] = YAML.load_file("#{config_path}/database.yml", aliases: true)
  vars[:salt] = YAML.load_file("#{config_path}/salts.yml", aliases: true)

  erb_source = File.read("#{config_path}/deploy-tools/wp-config.php.erb")
  rend = ERB.new(erb_source)
  res = rend.result(vars.instance_eval { binding })
  File.write("#{out_path}/wp-config.php", res)
end
