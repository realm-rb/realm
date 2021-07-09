# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(__FILE__)
loader.inflector.inflect('rom' => 'ROM')
loader.setup

require 'realm-core'
require 'rom'
require 'rom-sql'
require 'realm/rom/plugin'

# rubocop:enable Naming/FileName
