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
      (klass.try(:dependencies) || []).each do |d|
        fn = -> { resolve_dependable(sanitize_dependable(d.dependable), d.optional?) }
        kwargs[d.name] = d.lazy? ? fn : fn.call
      end
      klass.new(*args, **kwargs)
    end

    private

    def sanitize_dependable(dependable)
      return dependable.constantize if dependable.is_a?(String) && dependable.match(/^[A-Z]/)

      dependable
    end

    def resolve_dependable(dependable, optional)
      return self[dependable] if optional

      raise DependencyMissing, dependable unless key?(dependable)

      resolve(dependable)
    end
  end
end
