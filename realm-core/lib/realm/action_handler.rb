# frozen_string_literal: true

require 'dry-validation'

module Realm
  class ActionHandler
    extend Mixins::ContextInjection::ClassMethods
    include Mixins::AggregateMember
    include Mixins::RepositoryHelper

    class << self
      attr_reader :contracts

      def call(action: :handle, params: {}, runtime: nil)
        new(runtime: runtime).(action: action, params: params)
      end

      protected

      def require_permission(*names)
        # TODO: implement
      end

      def contract(&block)
        @method_contract = Class.new(Realm::Contract, &block).new
      end

      def contract_schema(...)
        contract { schema(...) }
      end

      def contract_params(...)
        contract { params(...) }
      end

      def contract_json(...)
        contract { json(...) }
      end

      alias schema_contract contract_schema
      alias params_contract contract_params
      alias json_contract contract_json

      def method_added(method_name)
        super
        return unless defined?(@method_contract)

        @contracts ||= {}
        @contracts[method_name] = @method_contract
        remove_instance_variable(:@method_contract)
      end
    end

    def initialize(runtime: nil)
      @runtime = runtime
    end

    def call(action: :handle, params: {})
      # TODO: check permissions
      raise CannotHandleAction.new(self, action) unless respond_to?(action)

      safe_params = validate(action, params.to_h)
      send(action, **safe_params)
    end

    protected

    delegate :context, to: :@runtime

    private

    def validate(action, params)
      contract = self.class.contracts && self.class.contracts[action]
      return params unless contract

      result = contract.(params)
      raise Realm::InvalidParams, result if result.failure?

      result.to_h
    end
  end
end
