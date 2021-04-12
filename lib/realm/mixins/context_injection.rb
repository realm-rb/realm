# frozen_string_literal: true

require 'realm/errors'

module Realm
  module Mixins
    module ContextInjection
      def self.included(base)
        base.extend(ClassMethods)
        base.prepend(Initializer)
      end

      module ClassMethods
        def inject(*names, &block)
          names.each do |name|
            define_method(name) do
              raise Realm::DependencyMissing, name unless context.key?(name)

              return context[name] unless block

              var = "@#{name}"
              return instance_variable_get(var) if instance_variable_defined?(var)

              instance_variable_set(var, block.(context[name]))
            end
          end
        end
      end

      module Initializer
        def initialize(*args, context: nil, **kwargs)
          @context = context || context_from_root_module || {}
          super(*args, **kwargs)
        end

        private

        def context_from_root_module
          root_module = self.class.module_parents[-2]
          root_module.realm.context if root_module.respond_to?(:realm)
        end
      end

      protected

      attr_reader :context
    end
  end
end
