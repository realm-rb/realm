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

    def register_factory(klass, *args, memoize: true, **kwargs)
      register(klass, memoize: memoize) do
        create(klass, *args, **kwargs)
      end
    end

    def register_all(hash)
      hash.each_pair do |key, value|
        register(key, value)
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
