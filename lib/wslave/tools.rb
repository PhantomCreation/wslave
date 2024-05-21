require 'fileutils'
require 'yaml'

##
# Various tools, utilities, and helpers for wslave.
class WSlaveTools
  def self.wslave_root?
    return true if File.exist?('./config/.wslave') &&
                   File.exist?('docker-compose.yml')

    puts 'This does not appear to be the root of a WSlave managed app.'
    puts 'Run command again from the root directory of a WSlave app.'
    false
  end

  def self.set_dev_perms(path = '.')
    unless Dir.exist?("#{path}/public/data")
      FileUtils.mkdir("#{path}/public/data")
      FileUtils.touch("#{path}/public/data/.gitkeep")
    end
    FileUtils.chown(nil, 'www-data', "#{path}/public/data")
    FileUtils.chmod(0o775, "#{path}/public/data")

    FileUtils.chown(nil, 'www-data', "#{path}/public/wp-content")
    FileUtils.chown(nil, 'www-data', Dir.glob("#{path}/public/wp-content/*"))
    FileUtils.chmod(0o775, "#{path}/public/wp-content")
    FileUtils.chmod(0o775, Dir.glob("#{path}/public/wp-content/*"))

    FileUtils.mkdir_p("#{path}/db")
    FileUtils.chown(nil, 'www-data', "#{path}/db")
    FileUtils.chmod(0o775, "#{path}/db")

    unless Dir.exist?("#{path}/db/active")
      FileUtils.mkdir("#{path}/db/active")
      FileUtils.touch("#{path}/db/active/.gitkeep")
    end
    FileUtils.chown(nil, 'www-data', "#{path}/db/active")
    FileUtils.chmod(0o775, "#{path}/db/active")

    unless Dir.exist?("#{path}/db/dev")
      FileUtils.mkdir("#{path}/db/dev")
      FileUtils.touch("#{path}/db/dev/.gitkeep")
    end
    FileUtils.chown(nil, 'www-data', "#{path}/db/dev")
    FileUtils.chmod(0o775, "#{path}/db/dev")

    unless Dir.exist?("#{path}/db/staging")
      FileUtils.mkdir("#{path}/db/staging")
      FileUtils.touch("#{path}/db/staging/.gitkeep")
    end
    FileUtils.chown(nil, 'www-data', "#{path}/db/staging")
    FileUtils.chmod(0o775, "#{path}/db/staging")

    unless Dir.exist?("#{path}/db/production")
      FileUtils.mkdir("#{path}/db/production")
      FileUtils.touch("#{path}/db/production/.gitkeep")
    end
    FileUtils.chown(nil, 'www-data', "#{path}/db/production")
    FileUtils.chmod(0o775, "#{path}/db/production")

  # The main reason the exception will fire is becasue the user doesn't belong to the
  #   www-data group; but there's other reasons such as the file being somehow being
  #   owned by root or the system not even supporting permissions (like some
  #   installations of Windows?).
  rescue Errno::EPERM => e
    puts "!!!WARNING!!! Unable to assign www-data group permissions! \n " \
         ">>> Unable to make folders writable for devlopment. <<<\n " \
         ">>> You will not be able to edit files or themes in the WP dev container! <<<\n"

    print " >>>> Original error: #{e.message}"
  end

  def self._check_and_mk_dirs(path = '.'); end

  def self.update_submodules
    `git submodule update --init --recursive`
  end

  def self.sync
    return unless wslave_root?

    update_submodules
    set_dev_perms
  end

  def self.web_server
    return unless wslave_root?

    @web_info = YAML.load_file('config/definitions.yml', aliases: true) if @web_info.nil?

    @web_info
  end

  def self.db_server
    return unless wslave_root?

    @db_info = YAML.load_file('config/database.yml', aliases: true) if @db_info.nil?

    @db_info
  end
end
