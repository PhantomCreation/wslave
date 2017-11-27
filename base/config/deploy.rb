# config valid only for current version of Capistrano
lock "3.10.0"

require 'yaml'
opts = YAML.load_file('config/definitions.yml')

set :application, opts['app']['name']
set :repo_url, opts['app']['repo']

deploy_method = opts['options']['deploy_method'] if opts.has_key?('options') &&
  opts['options'].has_key?('deploy_method')

case deploy_method
when 'scp'
  set :scm, :copy
else
end
