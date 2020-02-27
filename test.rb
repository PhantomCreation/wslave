puts ">> Changing directory to ensure isolation"
Dir.chdir(__dir__)
puts ">> Attempting to use wslave command to create an installation:"
`#{__dir__}/bin/wslave new tmp --wspath ./wstmp`
Dir.chdir("#{__dir__}/tmp")
`#{__dir__}/bin/wslave server`
