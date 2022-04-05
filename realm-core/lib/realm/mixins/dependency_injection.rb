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
          _dependencies.each { |d| define_dependency_method(instance, kwargs, d) }
          kwargs_without_dependencies = kwargs.reject { |k, _| _dependencies.any? { |d| d.name == k } }
          instance.send(:initialize, *args, **kwargs_without_dependencies, &block)
          instance
        end

        def inject(*dependables, **options)
          _dependencies.concat(dependables.map { |d| Dependency.new(d, **options) })
        end

        def dependencies
          _dependencies.freeze
        end

        def inherited(subclass)
          subclass.instance_variable_set(:@dependencies, _dependencies.dup)
          super
        end

        private

        def _dependencies
          @dependencies ||= []
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
