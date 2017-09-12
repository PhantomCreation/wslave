# config valid only for current version of Capistrano
lock "3.9.1"


require 'yaml'
opts = YAML.load_file('config/definitions.yml')

set :application, opts['app']['name']
set :repo_url, opts['app']['repo']
