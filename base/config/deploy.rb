# config valid only for current version of Capistrano
lock '3.18.0'

require 'yaml'
opts = YAML.load_file('config/definitions.yml', aliases: true)

set :application, opts['app']['name']
set :repo_url, opts['app']['repo']
