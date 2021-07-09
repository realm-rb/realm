# frozen_string_literal: true

require 'dry-container'

module Realm
  class Container
    include Dry::Container::Mixin
    include Enumerable

    def self.[](object)
      object.is_a?(Container) ? object : Container.new(object)
    end

    def initialize(hash = {})
      register_all(hash)
    end

    def register(key, contents = nil, options = {}, &block)
      options[:klass] ||= contents.class if contents && !contents.is_a?(::Hash)
      super(key, contents, options, &block)
    end

    def register_all(hash)
      hash.each_pair do |key, value|
        register(key, value)
      end
    end

    def register_factory(klass, *args, as: nil, memoize: true, **kwargs) # rubocop:disable Naming/MethodParameterName
      register(as || klass, klass: klass, memoize: memoize) do
        create(klass, *args, **kwargs)
      end
    end

    def create(klass, *args, **kwargs)
      (klass.try(:dependencies) || []).each do |d|
        fn = -> { resolve_dependable(sanitize_dependable(d.dependable), d.optional?) }
        kwargs[d.name] = d.lazy? ? fn : fn.call
      end
      klass.new(*args, **kwargs)
    end

    def [](key)
      resolve(key) if key?(key)
    end

    def resolve_all(klass)
      _container.each_with_object([]) do |(_, item), all|
        all << item.call if item.options[:klass] <= klass
      end
    end

    private

    def sanitize_dependable(dependable)
      dependable.is_a?(String) && dependable.match(/^[A-Z]/) ? dependable.constantize : dependable
    end

    def resolve_dependable(dependable, optional)
      raise DependencyMissing, dependable unless optional || key?(dependable)

      self[dependable]
    end
  end
end
