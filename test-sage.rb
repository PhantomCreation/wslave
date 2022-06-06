puts ">> Testing Sage theme generation..."
puts ">> NOTE: MUST BE RUN AFTER test.rb SUCCEEDS."
Dir.chdir("#{__dir__}/testing")

puts ">> Starting server..."
`bundle exec wslave server start`

puts ">> Creating Sage theme named \"test\"..."
`bundle exec wslave sage create test`

puts ">> Attempting to install theme dependencies and build..."
`bundle exec wslave sage update`
