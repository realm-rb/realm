# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

version = File.read(File.expand_path('../VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name        = 'realm-rom'
  spec.version     = version
  spec.authors     = ['developers@reevoo.com']
  spec.summary     = 'ROM SQL persistence plugin for Realm'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'
  spec.files = Dir['{lib}/**/*', 'Rakefile', 'README.md', 'LICENCE']

  spec.add_dependency 'realm-core'
  spec.add_dependency 'rom', '~> 5.2'
  spec.add_dependency 'rom-sql', '~> 3.2'

  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
