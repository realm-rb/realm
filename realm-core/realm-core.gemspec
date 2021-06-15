# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

version = File.read(File.expand_path('../VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name        = 'realm-core'
  spec.version     = version
  spec.authors     = ['developers@reevoo.com']
  spec.summary     = 'Domain layer framework following Domain-driven/CQRS design principles'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'
  spec.files = Dir['{lib}/**/*', 'Rakefile', 'README.md', 'LICENCE']

  spec.add_dependency 'activesupport', '~> 6.0'
  spec.add_dependency 'dry-container', '~> 0.7'
  spec.add_dependency 'dry-core', '~> 0.6'
  spec.add_dependency 'dry-initializer', '~> 3.0'
  spec.add_dependency 'dry-struct', '~> 1.4'
  spec.add_dependency 'dry-types', '~> 1.5'
  spec.add_dependency 'dry-validation', '~> 1.5'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
