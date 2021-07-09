# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(__FILE__)
loader.inflector.inflect('sns' => 'SNS')
loader.setup

require 'realm-core'
require 'aws-sdk-sns'
require 'aws-sdk-sqs'
require 'realm/sns/plugin'

# rubocop:enable Naming/FileName
