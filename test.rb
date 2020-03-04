puts ">> Changing directory to ensure isolation"
Dir.chdir(__dir__)
puts ">> Attempting to use wslave command to create an installation:"
`#{__dir__}/bin/wslave new testing --wspath ../ --version 5.3.2`
Dir.chdir("#{__dir__}/testing")
`bundle exec wslave server`
`bundle exec wslave sage test`
