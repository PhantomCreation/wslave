require 'erb'
require 'yaml'
require 'ostruct'

def GenerateNginxConfig(profile = 'production', out_path= './')
  config_path = File.dirname(File.expand_path(File.dirname(__FILE__)))
  server = {}
  #server[:name] =
  #server[:root] =
  #server[:php_sock_path] =
end
