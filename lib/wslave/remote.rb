require_relative 'tools'

##
# Remote Connection and Control for wslave.
class WSlaveRemote
  def self.ssh(profile = :production)
    return unless WSlaveTools.wslave_root?

    profile = profile.to_s
    web = WSlaveTools.web_server
    exec("ssh #{web['deployer']['user']}@#{web['deployer']['host'][profile]} -t \"cd #{web['deployer']['root']}/#{web['deployer']['fqdn'][profile]}; exec $SHELL -l\"")
  end

  def self.sql(profile = :production)
    reutrn unless WSlaveTools.wslave_root?
  end
end
