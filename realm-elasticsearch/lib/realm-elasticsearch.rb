# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(__FILE__)
loader.setup

require 'realm-core'
require 'typhoeus'
require 'elasticsearch'
require 'realm/elasticsearch/plugin'

# rubocop:enable Naming/FileName
