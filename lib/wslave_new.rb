require 'fileutils'
require 'rubygems'
require_relative 'wslave_tools'

class WSlaveNew
  def initialize(path, version)
    puts '⚙ Initializing Toolchain・・・'

    tc_path = File.expand_path "#{__dir__}/../base/"

    FileUtils.mkdir_p path

    Dir.chdir path
    
    puts "  > Setting up WordPress WSlave setup in: #{path}"
    FileUtils.cp_r Dir.glob("#{tc_path}/*"), path

    spec = Gem::Specification::load("#{__dir__}/../wslave.gemspec")
    File.open("#{path}/config/.wslave", 'w') {|f| f.write(spec.version)}

    `cd #{path} && git init && git add --all && git commit -am "initial commit by wslave"`

    `cd #{path} && git submodule add git://github.com/WordPress/WordPress.git public/wordpress`
    `cd #{path}/public/wordpress && git checkout #{version}-branch` if version != ''
    `cd #{path} && git submodule update --init --recursive public/wordpress`
    FileUtils.cp_r("#{path}/public/wordpress/wp-content", "#{path}/public/wp-content")
    FileUtils.mkdir("#{path}/public/wordpress/wp-content/uploads")
    FileUtils.touch("#{path}/public/wordpress/wp-content/uploads/.gitkeep")
    FileUtils.mkdir("#{path}/public/wordpress/wp-content/upgrade")
    FileUtils.touch("#{path}/public/wordpress/wp-content/upgrade/.gitkeep")
    Dir.chdir path
    WSlaveTools.set_dev_perms
    
    `cd #{path} && git add --all && git commit -am "Add and initialize WordPress#{version}"`
  end
end
