# frozen_string_literal: true

require 'active_support/core_ext/class'
require 'dry-core'

module Realm
  class Plugin
    extend Dry::Core::ClassAttributes

    defines :name

    def self.setup(_config, _container)
      raise NotImplementedError
    end
  end
end
