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

    class NotConvertibleToSchema < Realm::Error
      def initialize(thing)
        super("Not convertible to schema: #{thing}")
      end
    end

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

      def contract_schema(*imports, &block)
        imported_schemas = sanitize_schemas(imports)
        contract { schema(*imported_schemas, &block) }
      end

      def contract_params(*imports, &block)
        imported_schemas = sanitize_schemas(imports, :params)
        contract { params(*imported_schemas, &block) }
      end

      def contract_json(*imports, &block)
        imported_schemas = sanitize_schemas(imports, :json)
        contract { json(*imported_schemas, &block) }
      end

      def method_added(method_name)
        super
        return unless defined?(@method_contract)

        @contracts ||= {}
        @contracts[method_name] = @method_contract
        remove_instance_variable(:@method_contract)
      end

      private

      def sanitize_schemas(things, type = :schema)
        things.map { |thing| convert_to_schema(thing, type) }
      end

      def convert_to_schema(thing, type)
        return thing if thing.is_a? Dry::Schema::Processor # already a schema

        raise NotConvertibleToSchema, thing unless thing.respond_to?(:to_dry_schema)

        thing.to_dry_schema(type: type)
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
