Gem::Specification.new do |s|
  s.name        = 'wslave'
  s.version     = '0.0.1'
  s.licenses     = ['GPL-3.0', 'AGPL-3.0']
  s.summary     = '"Word Slave" generates and controls a WordPress installation'
  s.description = 'Word Slave includes the wslave command and a control library to generate a ' \
                  '"best practice" WordPress installation and includes a pre-rolled Docker ' \
                  'setup for running a development server and a Capistrano setup for deployment.'
  s.authors     = ['Rei Kagetsuki']
  s.email       = 'info@phantom.industries'
  s.homepage    = 'https://github.com/PhantomCreation/wslave'

  s.required_ruby_version = '>= 2.0.0'
                  Dir.glob('lib/**/*.rb') +
                  Dir.glob('bin/**/*.rb') +
                  Dir.glob('res/**/*.rb') +
                  ['wslave.gemspec']
  s.require_paths = ['lib']
  s.bindir = 'bin'
  s.executables << 'wslave'

  s.add_dependency 'thor'
  s.add_dependency 'haikunator'
  s.add_dependency 'capistrano', '~> 3.8.1'
  s.add_dependency 'capistrano-git-with-submodules', '~> 2.0'
end
