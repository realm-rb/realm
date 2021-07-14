# frozen_string_literal: true

require 'active_support/all'
require 'dry/core/constants'

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

    # port the construction method from Dry::Struct as it's not inherited
    def Struct(attributes = Dry::Core::Constants::EMPTY_HASH, &block) # rubocop:disable Naming/MethodName
      Class.new(Struct) do
        attributes.each { |a, type| attribute a, type }
        module_eval(&block) if block
      end
    end
  end
end
