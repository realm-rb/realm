# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

version = File.read(File.expand_path('./VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name        = 'realm-elasticsearch'
  spec.version     = version
  spec.authors     = ['developers@reevoo.com']
  spec.summary     = 'Elasticsearch plugin for Realm'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'
  spec.files = Dir['{lib}/**/*', 'Rakefile', 'README.md', 'LICENCE']

  spec.add_dependency 'elasticsearch', '~> 7.11'
  spec.add_dependency 'realm-core'
  spec.add_dependency 'typhoeus', '~> 1.4'
  spec.add_dependency 'zeitwerk', '~> 2.4'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
