require 'fileutils'
require 'rubygems'
require_relative 'wslave_tools'

class WSlaveUpdate
  def initialize()
    puts '⚙ Updating Toolchain・・・'

    path = Dir.pwd
    if !File.exist?("#{path}/config/.wslave")
    	puts "!!!This command must be run in a WSlave generated project!!!"
	    return
    end

    base_path = File.expand_path "#{__dir__}/../base/"
    template_path = File.expand_path "#{__dir__}/../templates/"


    Dir.chdir path
    
    FileUtils.cp("#{base_path}/Capfile", "#{path}/Capfile")
    # FileUtils.cp("#{base_path}/Gemfile", "#{path}/Gemfile")
    FileUtils.cp("#{base_path}/Rakefile", "#{path}/Rakefile")
    FileUtils.cp_r("#{base_path}/docker", "#{path}/docker")
    FileUtils.cp("#{base_path}/docker-compose.yml", "#{path}/docker-compose.yml")
    FileUtils.cp("#{base_path}/public/.htaccess", "#{path}/public/.htaccess")
    FileUtils.cp_r(Dir.glob("#{base_path}/config/*"), "#{path}/config")
    FileUtils.cp("#{template_path}/config/database.yml", "#{path}/config/database.yml") unless File.exist?  "#{path}/config/database.yml"
    FileUtils.cp("#{template_path}/config/definitions.yml", "#{path}/config/definitions.yml") unless File.exist?  "#{path}/config/definitions.yml"

    spec = Gem::Specification::load("#{__dir__}/../wslave.gemspec")
    FileUtils.rm("#{path}/config/.wslave")
    File.open("#{path}/config/.wslave", 'w') {|f| f.write(spec.version)}

    Dir.chdir path
    WSlaveTools.set_dev_perms(path) 
  end
end
