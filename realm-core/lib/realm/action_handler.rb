# frozen_string_literal: true

require 'dry-validation'
require 'active_support/core_ext/module/delegation'
require 'realm/error'
require 'realm/mixins/context_injection'
require 'realm/mixins/repository_helper'
require 'realm/mixins/aggregate_member'
require_relative 'action_handler/result'

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
        @method_contract = Class.new(Dry::Validation::Contract, &block).new
      end

      def contract_schema(&block)
        contract { schema(&block) }
      end

      def contract_params(&block)
        contract { params(&block) }
      end

      def contract_json(&block)
        contract { json(&block) }
      end

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
