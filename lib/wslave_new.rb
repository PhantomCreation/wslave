require 'fileutils'
require 'rubygems'
require 'pathname'
require 'git'

require_relative 'wslave_tools'

class WSlaveNew
  def initialize(path, version = '', wspath = '', wppath = '')
    puts '⚙ Initializing Toolchain・・・'

    if (wspath != '')
      manual_path = true
      if ((Pathname.new(wspath)).absolute?)
        base_path = File.expand_path "#{wspath}/base/"
        template_path = File.expand_path "#{wspath}/templates/"
      else
        base_path = File.expand_path "#{path}/#{wspath}/base/"
        template_path = File.expand_path "#{path}/#{wspath}/templates/"
      end
    else
      manual_path = false
      wspath = "#{__dir__}/.."
      base_path = File.expand_path "#{wspath}/base/"
      template_path = File.expand_path "#{wspath}/templates/"
    end

    FileUtils.mkdir_p path

    Dir.chdir path

    puts "  > Setting up WordPress WSlave setup in: #{path}"
    FileUtils.cp_r Dir.glob("#{base_path}/*"), path
    FileUtils.cp_r Dir.glob("#{template_path}/*"), path
    add_path_to_Gemspec(wspath, path) if manual_path

    spec = Gem::Specification::load("#{wspath}/wslave.gemspec")
    File.open("#{path}/config/.wslave", 'w') {|f| f.write(spec.version)}

    `cd #{path} && git init && git add --all && git commit -am "initial commit by wslave"`

    if (wppath != '')
      wppath = File.expand_path(wppath)
      puts "  >> Checking wppath (#{wppath}) ..."
      if (File.directory? wppath)
        puts "  >> wppath is a folder. Copying..."
        FileUtils.cp_r wppath, "public/wordpress"
        `cd public/wordpress`
        `git clean -fdx; git stash`
        `git checkout master`
        `git pull`
      end
    end

    `cd #{path} && git submodule add git://github.com/WordPress/WordPress.git public/wordpress`
    `cd #{path} && git submodule update --init --recursive public/wordpress`
    if (version == 'edge' || version == 'master')
      `cd #{path}/public/wordpress && git checkout master`
    elsif version != ''
      `cd #{path}/public/wordpress && git checkout #{version}`
    else
      `cd #{path}/public/wordpress && git checkout #{get_stable_branch_version("#{path}/public/wordpress")}-branch`
    end

    puts "  > Preparing detached content directory"
    FileUtils.cp_r("#{path}/public/wordpress/wp-content", "#{path}/public/wp-content")
    FileUtils.mkdir("#{path}/public/wp-content/uploads") unless Dir.exist?("#{path}/public/wp-content/uploads")
    FileUtils.touch("#{path}/public/wp-content/uploads/.gitkeep")
    FileUtils.mkdir("#{path}/public/wp-content/upgrade") unless Dir.exist?("#{path}/public/wp-content/upgrade")
    FileUtils.touch("#{path}/public/wp-content/upgrade/.gitkeep")
    Dir.chdir path

    puts "  > Preparing static data directory"
    FileUtils.mkdir("#{path}/public/data") unless Dir.exist?("#{path}/public/data")

    puts "  > Setting permissions"
    WSlaveTools.set_dev_perms

    `cd #{path} && git add --all && git commit -am "Add and initialize WordPress#{version}"`
    puts "  > Done!"
  end

  def add_path_to_Gemspec(wspath, path)
    gemtext = File.read("#{path}/Gemfile")
    gemtext.gsub!("gem 'wslave'", "gem 'wslave', path: '#{wspath}'")
    File.open("#{path}/Gemfile", "w") {|gemfile| gemfile.puts gemtext}
  end

  def get_stable_branch_version(path)
    latest_major = 5
    latest_minor = 7

    reg = /^(\d*)\.(\d)-branch$/
    puts "> Checking for WordPress versions in: #{path}"
    cdir = Dir.pwd()
    Dir.chdir(path)
    g = Git.open("./")
    g.branches.remote.each do |branch|
      ver = reg.match(branch.name)
      if (ver) # If the branch matched the x.y-branch pattern
        if ((ver[1].to_i >= latest_major) && (ver[2].to_i > latest_minor))
          latest_major = ver[1].to_i
          latest_minor = ver[2].to_i
        end
      end

    end
    Dir.chdir(cdir)

    latest = "#{latest_major}.#{latest_minor}"
    puts "> Detected latest WordPress version as: #{latest}"
    latest
  end
end
