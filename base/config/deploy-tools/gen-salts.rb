require 'securerandom'
require 'yaml'

config_path = File.dirname(File.expand_path(File.dirname(__FILE__)))

if File.exist?("#{config_path}/salts.yml")
  puts "Salts already generated! Refusing to overwrite them!"
else
  salts = {
    AUTH_KEY:         SecureRandom.base64(24),
    SECURE_AUTH_KEY:  SecureRandom.base64(24),
    LOGGED_IN_KEY:    SecureRandom.base64(24),
    NONCE_KEY:        SecureRandom.base64(24),
    AUTH_SALT:        SecureRandom.base64(24),
    SECURE_AUTH_SALT: SecureRandom.base64(24),
    LOGGED_IN_SALT:   SecureRandom.base64(24),
    NONCE_SALT:       SecureRandom.base64(24)
  }

  File.open("#{config_path}/salts.yml", 'w') {|f| f.write salts.to_yaml }
end
