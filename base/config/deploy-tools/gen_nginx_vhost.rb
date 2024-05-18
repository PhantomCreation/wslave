require 'erb'
require 'yaml'
require 'ostruct'

def generate_nginx_config(_profile = 'production', _out_path = './')
  config_path = File.dirname(__dir__)
  server = {}
  # server[:name] =
  # server[:root] =
  # server[:php_sock_path] =
end
