# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'realm/error'

module Realm
  module Mixins
    module DependencyInjection
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def new(*args, **kwargs, &block)
          instance = allocate
          @injecting ||= []
          @injecting.each { |spec| define_dependency_method(instance, kwargs, spec) }
          instance.send(:initialize, *args, **kwargs.reject { |k, _| @injecting.any? { |i| i[:name] == k } }, &block)
          instance
        end

        def inject(*things, as: nil, optional: false, lazy: false)
          @injecting ||= []
          things.each do |t|
            @injecting << {
              name: as || t.to_s.demodulize.underscore.to_sym,
              injectable: t,
              optional: optional,
              lazy: lazy,
            }
          end
        end

        def dependencies
          @injecting.clone
        end

        private

        def define_dependency_method(instance, kwargs, spec)
          name = spec[:name]
          dependency = kwargs[name]
          instance.singleton_class.class_eval do
            define_method(name) do
              return dependency unless spec[:lazy]

              var = "@#{name}"
              return instance_variable_get(var) if instance_variable_defined?(var)

              instance_variable_set(var, dependency.respond_to?(:call) ? dependency.call : dependency)
            end
            protected name
          end
        end
      end
    end
  end
end
