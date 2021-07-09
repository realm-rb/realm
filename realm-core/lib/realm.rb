# frozen_string_literal: true

require 'active_support/all'

module Realm
  class << self
    # Setup realm in test/console
    def setup(root_module, **options)
      config = Realm::Config.new(root_module: root_module, **options)
      Realm::Builder.setup(config)
    end

    # Bind realm in service/engine
    def bind(root_module, **options)
      setup(root_module, **options).tap do |builder|
        root_module.define_singleton_method(:realm) { builder.runtime }
      end
    end
  end
end
