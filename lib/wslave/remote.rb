require_relative 'tools'

##
# Remote Connection and Control for wslave.
class WSlaveRemote
  # Check that web server information is set.
  def self._check_web_init(info, profile)
    if info['deployer']['user'].nil? ||
       info['deployer']['host'][profile].nil? ||
       info['deployer']['fqdn'][profile].nil? ||
       info['deployer']['root'].nil?
      puts 'Unable to proceed. Missing information from config/definitions.yml.'
      return false
    end

    true
  end

  # Check that database server information is set.
  def self._check_db_info(info, profile)
    if info[profile]['host'].nil? ||
       info[profile]['username'].nil? ||
       info[profile]['password'].nil? ||
       info[profile]['database'].nil?
      puts 'Unable to proceed. Missing information from config/database.yml.'
      return false
    end

    true
  end

  def self.ssh(profile = :production)
    return unless WSlaveTools.wslave_root?

    profile = profile.to_s
    web = WSlaveTools.web_server
    return unless _check_web_init(web, profile)

    exec(
      "ssh #{web['deployer']['user']}@#{web['deployer']['host'][profile]} -t " \
      "\"cd #{web['deployer']['root']}/#{web['deployer']['fqdn'][profile]}; " \
      'exec $SHELL -l"'
    )
  end

  def self.sql(profile = :production)
    reutrn unless WSlaveTools.wslave_root?

    profile = profile.to_s
    web = WSlaveTools.web_server
    db = WSlaveTools.db_server
    return unless _check_web_init(web, profile)
    return unless _check_db_info(db, profile)

    exec(
      "ssh #{web['deployer']['user']}@#{web['deployer']['host'][profile]} -t " \
      "\"cd #{web['deployer']['root']}/#{web['deployer']['fqdn'][profile]}; " \
      "exec mysql --host='#{db[profile]['host']}' --user='#{db[profile]['username']}' --password='#{db[profile]['password']}' #{db[profile]['database']} \""
    )
  end
end
