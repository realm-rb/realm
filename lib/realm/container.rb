# frozen_string_literal: true

require 'dry-container'
require 'active_support/core_ext/string'
require 'active_support/core_ext/object/try'
require 'realm/error'

module Realm
  class Container
    include Dry::Container::Mixin

    def self.[](object)
      object.is_a?(Container) ? object : Container.new(object)
    end

    def initialize(hash = {})
      register_all(hash)
    end

    def [](key)
       resolve(key) if key?(key)
    end

    alias register_value register # the register method kwargs are destructuring event instances for some reason

    def register(thing, *args, instantiate: true, memoize: true, **kwargs)
      return super(thing, args[0]) unless thing.respond_to?(:new) && instantiate

      super(thing, memoize: memoize) do
        create(thing, *args, **kwargs)
      end
    end

    def register_all(hash)
      hash.each_pair do |key, value|
        register_value(key, value)
      end
    end

    def create(klass, *args, **kwargs)
      (klass.try(:dependencies) || []).each do |spec|
        fn = -> { resolve_injectable(sanitize_injectable(spec[:injectable]), spec[:optional]) }
        kwargs[spec[:name]] = spec[:lazy] ? fn : fn.call
      end
      klass.new(*args, **kwargs)
    end

    private

    def sanitize_injectable(injectable)
      return injectable.constantize if injectable.is_a?(String) && injectable.match(/^[A-Z]/)

      injectable
    end

    def resolve_injectable(injectable, optional)
      return self[injectable] if optional

      raise DependencyMissing, injectable unless key?(injectable)

      resolve(injectable)
    end
  end
end
