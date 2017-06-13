require File.expand_path('../lib/ru/version', __FILE__)

Gem::Specification.new do |s|
  s.authors     = ['Tom Benner', 'Alexander Pavlenko']
  s.email       = ['tombenner@gmail.com', 'alerticus@gmail.com']
  s.description = s.summary = %q{Ruby in your shell!}
  s.homepage    = 'https://github.com/AlexanderPavlenko/ru'

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.name          = 'ru2'
  s.executables   = ['ru']
  s.require_paths = ['lib']
  s.version       = Ru::VERSION
  s.license       = 'MIT'

  s.add_dependency 'activesupport', '>= 3.2.0'

  s.add_development_dependency 'appraisal', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 3.1'
end
