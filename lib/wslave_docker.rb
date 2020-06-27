require_relative 'wslave_tools'
require 'fileutils'

class WSlaveDocker
  def initialize
    puts 'Initializing WSlave Docker Control'
  end

  def server(command = :start, force = false, volume = false)
    case (command)
    when :start
      start(force, volume)
    when :stop
      stop(force, volume)
    end
  end

  def start(force = false, volume = false)
    return unless _check()
    _force_down() if force
    `docker-compose down#{volume ? ' -v' : ''}` # Shutdown existing instances
    _unfuck_dot_htaccess()
    WSlaveTools.set_dev_perms
    `docker-compose up -d`
  end

  def stop(force = false, volume = false)
    return unless _check()
    _force_down() if force
    `docker-compose down#{volume ? ' -v' : ''}`
  end

  def _check()
    return true if (File.exist?("./config/.wslave") &&
                    File.exist?("docker-compose.yml"))
    puts "This does not appear to be the root of a WSlave managed app."
    false
  end

  def _force_down()
    `docker-compose down --remove-orphans`
  end

  # Sometimes the docker container or a windows fs will screw up or delete .htaccess
  def _unfuck_dot_htaccess()
    begin
      FileUtils.cp_r("#{__dir__}/../base/public/.htaccess", "./public/.htaccess")
      # FileUtils.chmod(0444, "./public/.htaccess")
    rescue => e
      # noop
    end
  end
end
