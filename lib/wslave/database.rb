require_relative 'tools'
require 'fileutils'

##
# Database utilities and helpers.
class WSlaveDatabase
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

  def dev_snapshot
    dev_backup
    dev_activate
  end

  def _check
    return true if File.exist?('./config/.wslave')

    puts 'This does not appear to be the root of a WSlave managed app.'
    false
  end
end
