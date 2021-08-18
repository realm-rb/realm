# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'realm'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.ignore(__FILE__)
loader.setup

require 'realm/internal_event_loop/plugin'

# rubocop:enable Naming/FileName
