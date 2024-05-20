require_relative 'tools'
require 'fileutils'
require 'yaml'

##
# Database utilities and helpers.
class WSlaveDatabase
  @opts = {}
  def initialize
    puts 'Initializing WSlave Database Control'
  end

  def rm_dbfile(profile)
    return unless _check

    puts "Deleting ./db/#{profile}/wordpress.sql"
    FileUtils.rm_f("./db/#{profile}/wordpress.sql")
  end

  def dev_backup
    return unless _check

    rm_dbfile('dev')
    puts 'Creating backup of development database...'
    # NOTE: Currently mysqldump is not available on the docker container,
    # but mariadb-dump (the same tool with a different name) is.
    `docker compose exec db sh -c "mariadb-dump --single-transaction -hlocalhost -uroot -pwordpress wordpress > /db/wordpress.sql"`
    `docker compose exec db sh -c "chown :www-data /db/wordpress.sql"`
    `docker compose exec db sh -c "chmod 664 /db/wordpress.sql"`
  end

  def dev_activate
    return unless _check

    rm_dbfile('active')
    FileUtils.cp('./db/dev/wordpress.sql', './db/active/wordpress.sql')
  end

  def _rm_dbfile(profile)
    # TODO
    #puts "Deleting db/#{profile}/wordpress.sql"
    #FileUtils.rm_f("db/#{profile}/wordpress.sql")
  end

  def _replace_active_urls
    # TODO
    #puts 'Replacing Production and Staging URLs for local development/re-deployment...'
    #db_data = File.read('db/active/wordpress.sql')

    #db_data = db_data.gsub(/#{@opts['deployer']['fqdn']['staging']}/, 'localhost:8000') if @opts['deployer']['fqdn']['staging'] != ''
    #db_data = db_data.gsub(/#{@opts['deployer']['fqdn']['production']}/, 'localhost:8000') if @opts['deployer']['fqdn']['production'] != ''

    #File.open('db/active/wordpress.sql', 'w') { |file| file.puts db_data }
  end

  def staging_backup
  end

  def staging_activate
    # TODO
    #rm_dbfile('active')
    #FileUtils.cp('db/staging/wordpress.sql', 'db/active/wordpress.sql')
    #_replace_active_urls
  end

  def production_backup
  end

  def production_activate
    # TODO
    #rm_dbfile('active')
    #FileUtils.cp('db/production/wordpress.sql', 'db/active/wordpress.sql')
    #_replace_active_urls
  end

  def dev_snapshot
    dev_backup
    dev_activate
  end

  def _check
    if File.exist?('./config/.wslave')
      @opts = YAML.load_file('./config/definitions.yml')
      return true
    end

    puts 'This does not appear to be the root of a WSlave managed app.'
    false
  end
end
