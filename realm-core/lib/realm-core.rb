# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'realm'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(__FILE__)
loader.setup

# rubocop:enable Naming/FileName
