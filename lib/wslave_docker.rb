require_relative 'wslave_tools'
require 'fileutils'

class WSlaveDocker
  def initialize
    puts 'Initializing WSlave Docker Control'
  end

  def server(command = :start, force = false)
    case (command)
    when :start
      start(force)
    when :stop
      stop(force)
    when :reset
      reset(force)
    when :remove
      remove(force)
    when :log
      log()
    when :console
      console()
    else
      puts "server subcommand \"#{command.to_s}\" not found."
      puts "Available commands: start stop log console"
    end
  end

  def start(force = false)
    return unless _check()
    _force_down() if force
    `docker-compose stop` # Shutdown existing instances
    _unfuck_dot_htaccess()
    WSlaveTools.set_dev_perms
    `docker-compose build`
    `docker-compose start -d`
    `docker-compose up -d`
  end

  def stop(force = false)
    return unless _check()
    _force_down() if force
    `docker-compose stop`
  end

  def reset(force = false)
    return unless _check()
    _force_down() if force
    `docker-compose down -v`
    `docker-compose build`
    `docker-compose up -d`
  end

  def remove(force = false)
    return unless _check()
    _force_down() if force
    `docker-compose down -v`
  end

  def log()
    return unless _check()
    begin
      system("docker-compose logs -f")
    rescue Exception => e
      puts "\n\nEnding log trace. NOTE: Server containers are still running!\n\n"
      return
    end
  end

  def console()
    return unless _check()
    system("docker-compose exec nweb /bin/bash")
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
