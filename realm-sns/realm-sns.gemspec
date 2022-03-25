# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

version = File.read(File.expand_path('./VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name        = 'realm-sns'
  spec.version     = version
  spec.authors     = ['developers@reevoo.com']
  spec.summary     = 'SNS/SQS plugin for Realm'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'
  spec.files = Dir['{lib}/**/*', 'Rakefile', 'README.md', 'LICENCE']

  spec.add_dependency 'aws-sdk-sns', '~> 1.36'
  spec.add_dependency 'aws-sdk-sqs', '~> 1.34'
  spec.add_dependency 'realm-core'
  spec.add_dependency 'zeitwerk', '~> 2.4'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
