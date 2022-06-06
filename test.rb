puts ">> Changing directory to ensure isolation."
Dir.chdir(__dir__)

puts ">> Checking for pre-cloned wordpress..."
wppath = File.expand_path("#{__dir__}/dist/wordpress")
if (!(File.directory? wppath))
  puts ">> wordpress not found, pre-cloning.\n" +
    "NOTE: After testing, you can remove the dist/wordpress directory."
  `git clone https://github.com/WordPress/WordPress.git #{wppath}`
else
  puts ">> wordpress directory found, skipping clone."
end

puts ">> Attempting to use wslave command to create an installation..."
#`#{__dir__}/bin/wslave new testing --wspath ../ --version 5.4`
#`#{__dir__}/bin/wslave new testing --wspath ../`
`#{__dir__}/bin/wslave new testing --wspath ../ --wppath #{wppath}`
puts ">> wslave installation created."
Dir.chdir("#{__dir__}/testing")

puts ">> Starting server..."
`bundle exec wslave server start`
