class WSlaveSage
  def initialize(name, version)
    unless File.exist?("./config/.wslave")
      puts "This command must be run in the root of a WSlave setup"
    end
  
    `cd public/wp-content/themes && composer create-project roots/sage #{name} #{version}`
  end
end
