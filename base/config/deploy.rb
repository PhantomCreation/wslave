# config valid only for current version of Capistrano
lock '3.18.0'

require 'yaml'
opts = YAML.load_file('config/definitions.yml', aliases: true)

set :application, opts['app']['name']
set :repo_url, opts['app']['repo']

deploy_method = opts['options']['deploy_method'] if opts.key?('options') &&
                                                    opts['options'].key?('deploy_method')

case deploy_method
when 'scp'
  set :scm, :copy
end
