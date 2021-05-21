# frozen_string_literal: true

require 'dry-container'
require 'active_support/core_ext/object/try'

module Realm
  class Container
    include Dry::Container::Mixin

    def self.[](object)
      object.is_a?(Container) ? object : Container.new(object)
    end

    def initialize(hash = {})
      register_all(hash)
    end

    def register(thing, *args, memoize: true, **kwargs)
      return super(thing, args[0]) unless thing.respond_to?(:new)

      container = self
      super(thing, memoize: memoize) do
        (thing.try(:dependencies) || {}).each_pair do |key, dependency|
          kwargs[key] = container.resolve(dependency)
        end
        thing.new(*args, **kwargs)
      end
    end

    def register_all(hash)
      hash.each_pair do |key, value|
        register(key, value)
      end
    end
  end
end
