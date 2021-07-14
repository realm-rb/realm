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
        imported_schemas = sanitize_schemas(imports, :Params)
        contract { params(*imported_schemas, &block) }
      end

      def contract_json(*imports, &block)
        imported_schemas = sanitize_schemas(imports, :JSON)
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

      def sanitize_schemas(things, method_name = :define)
        things.map { |thing| convert_to_schema(thing, method_name) }
      end

      def convert_to_schema(thing, method_name)
        return thing if thing.is_a? Dry::Schema::Processor

        raise NotConvertibleToSchema, thing unless thing.respond_to?(:schema)

        # lambda to be accessible within Dry::Schema context
        convert = ->(t) { t.respond_to?(:schema) ? convert_to_schema(t, method_name) : t }

        Dry::Schema.send(method_name) do
          thing.schema.type.keys.each do |key|

            if key.required?
              if key.type.constructor_type == Dry::Types::Array::Constructor # array type
                required(key.name).array(convert.(key.type.member))
              elsif key.respond_to?(:schema) # struct
                required(key.name).hash(convert.(key))
              else
                required(key.name).filled(key.type)
              end
            else
              if key.type.constructor_type == Dry::Types::Array::Constructor # array type
                optional(key.name).array(convert.(key.type.member))
              elsif key.respond_to?(:schema) # struct
                optional(key.name).hash(convert.(key))
              else
                optional(key.name).maybe(key.type)
              end
            end
          end
        end
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
