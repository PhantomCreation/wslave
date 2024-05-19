Gem::Specification.new do |s|
  s.metadata['rubygems_mfa_required'] = 'true'

  s.name        = 'wslave'
  s.version     = '0.4.0'
  s.licenses    = ['GPL-3.0', 'AGPL-3.0']
  s.summary     = '"Word Slave" generates and controls a WordPress installation'
  s.description = 'Word Slave includes the wslave command and a control library to generate a ' \
                  '"best practice" WordPress installation and includes a pre-rolled Docker ' \
                  'setup for running a development server and a Capistrano setup for deployment.'
  s.authors     = ['Rei Kagetsuki']
  s.email       = 'info@phantom.industries'
  s.homepage    = 'https://github.com/PhantomCreation/wslave'

  s.required_ruby_version = '>= 3.0'
  s.files =       Dir.glob('lib/**/*.rb', File::FNM_DOTMATCH) +
                  Dir.glob('bin/**/*.rb', File::FNM_DOTMATCH) +
                  Dir.glob('base/**/*', File::FNM_DOTMATCH) +
                  Dir.glob('templates/**/*', File::FNM_DOTMATCH) +
                  ['wslave.gemspec']
  s.require_paths = ['lib']
  s.bindir = 'bin'
  s.executables << 'wslave'

  s.add_dependency 'git', '~> 1.18', '1.18.0'

  s.add_dependency 'haikunator', '~> 1.1', '1.1.1'
  s.add_dependency 'thor', '~> 1.3', '1.3.1'
end
