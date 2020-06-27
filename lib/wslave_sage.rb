class WSlaveSage
  def self.create(name, version)
    unless File.exist?("./config/.wslave")
      puts "This command must be run in the root of a WSlave setup"
    end
  
    puts "Creating Sage theme at public/wp-content/themes/#{name}"
    `cd public/wp-content/themes && composer create-project roots/sage #{name} #{version}`
  end
end
