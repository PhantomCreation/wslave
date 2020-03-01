puts ">> Changing directory to ensure isolation"
Dir.chdir(__dir__)
puts ">> Attempting to use wslave command to create an installation:"
`#{__dir__}/bin/wslave new testing --wspath ../`
Dir.chdir("#{__dir__}/testing")
#`#{__dir__}/bin/wslave server`
`bundle exec wslave server`
