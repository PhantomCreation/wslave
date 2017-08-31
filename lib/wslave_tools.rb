require 'fileutils'

class WSlaveTools
  def self.wslave_root?()
    return true if (File.exist?("./config/.wslave") &&
                    File.exist?("Dockerfile") &&
                    File.exist?("docker-compose.yml"))
    puts "This does not appear to be the root of a WSlave managed app."
    puts "Run command again from the root directory of a WSlave app."
    false
  end

  def self.set_dev_perms
    begin
      FileUtils.chown(nil, 'www-data', 'public/wp-content/themes')
      FileUtils.chown(nil, 'www-data', 'public/wp-content/uploads')
      FileUtils.chown(nil, 'www-data', 'public/wp-content/plugins')
      FileUtils.chown(nil, 'www-data', 'public/wp-content/upgrade')
    rescue Errno::EPERM
      puts "!!!WARNING!!! Your user does not belong to the www-data group!\n" \
        " >>> Unable to make folders writable for devlopment. <<<\n" \
        " >>> You will not be able to edit files or themes in the WP dev container! <<<\n"
    end
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
