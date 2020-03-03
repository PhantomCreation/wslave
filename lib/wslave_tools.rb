require 'fileutils'

class WSlaveTools
  def self.wslave_root?()
    return true if (File.exist?("./config/.wslave") &&
                    File.exist?("docker-compose.yml"))
    puts "This does not appear to be the root of a WSlave managed app."
    puts "Run command again from the root directory of a WSlave app."
    false
  end

  def self.set_dev_perms(path = '.')
    begin
      unless Dir.exist?("#{path}/public/wp-content/upgrade")
        FileUtils.mkdir("#{path}/public/wp-content/upgrade")
        FileUtils.touch("#{path}/public/wp-content/upgrade/.gitkeep")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/public/wp-content/themes")
      FileUtils.chmod(0775, "#{path}/public/wp-content/themes")
      FileUtils.chown(nil, 'www-data', "#{path}/public/wp-content/uploads")
      FileUtils.chmod(0775, "#{path}/public/wp-content/uploads")
      FileUtils.chown(nil, 'www-data', "#{path}/public/wp-content/plugins")
      FileUtils.chmod(0775, "#{path}/public/wp-content/plugins")
      FileUtils.chown(nil, 'www-data', "#{path}/public/wp-content/upgrade")
      FileUtils.chmod(0775, "#{path}/public/wp-content/upgrade")

      unless Dir.exist?("#{path}/db")
        FileUtils.mkdir("#{path}/db")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/db")
      FileUtils.chmod(0775, "#{path}/db")

      unless Dir.exist?("#{path}/db/active")
        FileUtils.mkdir("#{path}/db/active")
        FileUtils.touch("#{path}/db/active/.gitkeep")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/db/active")
      FileUtils.chmod(0775, "#{path}/db/active")

      unless Dir.exist?("#{path}/db/dev")
        FileUtils.mkdir("#{path}/db/dev")
        FileUtils.touch("#{path}/db/dev/.gitkeep")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/db/dev")
      FileUtils.chmod(0775, "#{path}/db/dev")

      unless Dir.exist?("#{path}/db/staging")
        FileUtils.mkdir("#{path}/db/staging")
        FileUtils.touch("#{path}/db/staging/.gitkeep")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/db/staging")
      FileUtils.chmod(0775, "#{path}/db/staging")

      unless Dir.exist?("#{path}/db/production")
        FileUtils.mkdir("#{path}/db/production")
        FileUtils.touch("#{path}/db/production/.gitkeep")
      end
      FileUtils.chown(nil, 'www-data', "#{path}/db/production")
      FileUtils.chmod(0775, "#{path}/db/production")
    rescue Errno::EPERM
      puts "!!!WARNING!!! Your user does not belong to the www-data group!\n" \
        " >>> Unable to make folders writable for devlopment. <<<\n" \
        " >>> You will not be able to edit files or themes in the WP dev container! <<<\n"
    end
  end

  def self._check_and_mk_dirs(path = '.')
  end

  def self.update_submodules
    `git submodule update --init --recursive`
  end

  def self.sync
    if wslave_root?
      update_submodules
      set_dev_perms
    end
  end
end
