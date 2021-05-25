# frozen_string_literal: true

require 'active_support/core_ext/module/introspection'
require 'active_support/core_ext/class/attribute'

module Realm
  module Mixins
    module Controller
      def self.included(base)
        base.class_attribute(:aggregate_name)
        base.extend(ClassMethods)
      end

      def domain_runtime
        @domain_runtime ||= root_domain_runtime.session(domain_context)
      end

      def domain_context
        {}
      end

      def query(identifier, params = {})
        domain_runtime.query(get_dispatchable(identifier), params)
      end

      def run(identifier, params = {})
        domain_runtime.run(get_dispatchable(identifier), params)
      end

      def run_as_job(identifier, params = {})
        domain_runtime.run_as_job(get_dispatchable(identifier), params)
      end

      private

      def get_dispatchable(identifier)
        return identifier if identifier.respond_to?(:call)

        [aggregate_name, identifier].compact.join('.')
      end

      def root_domain_runtime
        self.class.module_parents[-2].realm
      end

      module ClassMethods
        def with_aggregate(name)
          self.aggregate_name = name
        end
      end
    end
  end
end
