# frozen_string_literal: true

module Realm
  module Mixins
    module DependencyInjection
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def new(*args, **kwargs, &block)
          instance = allocate
          deps.each { |d| define_dependency_method(instance, kwargs, d) }
          kwargs_without_dependencies = kwargs.reject { |k, _| deps.any? { |d| d.name == k } }
          instance.send(:initialize, *args, **kwargs_without_dependencies, &block)
          instance
        end

        def inject(*dependables, **options)
          deps.concat(dependables.map { |d| Dependency.new(d, **options) })
        end

        def dependencies
          deps.freeze
        end

        def inherited(subclass)
          subclass.instance_variable_set(:@deps, @deps.dup)
          super
        end

        private

        def deps
          @deps ||= []
        end

        def define_dependency_method(instance, kwargs, spec)
          dependency = kwargs[spec.name]
          instance.singleton_class.class_eval do
            define_method(spec.name) do
              return dependency unless spec.lazy?

              var = "@#{spec.name}"
              return instance_variable_get(var) if instance_variable_defined?(var)

              instance_variable_set(var, dependency.respond_to?(:call) ? dependency.call : dependency)
            end
            protected spec.name
          end
        end
      end
    end
  end
end
