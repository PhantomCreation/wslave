require 'fileutils'
require 'rubygems'
require_relative 'tools'

##
# Handles updating the toolchain in a wslave project.
class WSlaveUpdate
  def initialize
    puts '⚙ Updating Toolchain・・・'

    path = Dir.pwd
    unless File.exist?("#{path}/config/.wslave")
      puts '!!!This command must be run in a WSlave generated project!!!'
      return
    end

    base_path = File.expand_path "#{__dir__}/../../base/"
    template_path = File.expand_path "#{__dir__}/../../templates/"

    Dir.chdir path

    FileUtils.cp("#{base_path}/Rakefile", "#{path}/Rakefile")
    FileUtils.cp_r("#{base_path}/docker", "#{path}/")
    FileUtils.cp("#{base_path}/docker-compose.yml", "#{path}/docker-compose.yml")
    FileUtils.cp("#{base_path}/public/.htaccess", "#{path}/public/.htaccess")
    FileUtils.cp("#{base_path}/public/wp-config.php", "#{path}/public/wp-config.php")
    FileUtils.cp("#{template_path}/config/database.yml", "#{path}/config/database.yml") unless File.exist? "#{path}/config/database.yml"
    FileUtils.cp("#{template_path}/config/definitions.yml", "#{path}/config/definitions.yml") unless File.exist? "#{path}/config/definitions.yml"

    spec = Gem::Specification.load("#{__dir__}/../../wslave.gemspec")
    FileUtils.rm("#{path}/config/.wslave")
    File.write("#{path}/config/.wslave", spec.version)

    Dir.chdir path
    WSlaveTools.set_dev_perms(path)
  end
end
