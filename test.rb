puts ">> Changing directory to ensure isolation."
Dir.chdir(__dir__)

puts ">> Attempting to use wslave command to create an installation..."
`#{__dir__}/bin/wslave new testing --wspath ../ --version 5.4`
puts ">> wslave installation created."
Dir.chdir("#{__dir__}/testing")

puts ">> Starting server..."
`bundle exec wslave server start`

puts ">> Creating Sage theme named \"test\"..."
`bundle exec wslave sage create test`

puts ">> Attempting to install theme dependencies and build..."
`bundle exec wslave sage update`
