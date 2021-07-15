# frozen_string_literal: true

require 'dry-validation'

module Realm
  class Contract < Dry::Validation::Contract
    class NotConvertibleToSchema < Realm::Error
      def initialize(thing)
        super("Not convertible to schema: #{thing}")
      end
    end

    class << self
      def schema(*external_schemas, **attributes, &block)
        super(*sanitize_schemas(external_schemas, attributes), &block)
      end

      def params(*external_schemas, **attributes, &block)
        super(*sanitize_schemas(external_schemas, attributes), &block)
      end

      def json(*external_schemas, **attributes, &block)
        super(*sanitize_schemas(external_schemas, attributes), &block)
      end

      private

      def sanitize_schemas(things, attributes, type = :schema)
        things << Realm.Struct(attributes) if attributes.present?
        things.map { |thing| convert_to_schema(thing, type) }
      end

      def convert_to_schema(thing, type)
        return thing if thing.is_a? Dry::Schema::Processor # already a schema

        raise NotConvertibleToSchema, thing unless thing.respond_to?(:to_dry_schema)

        thing.to_dry_schema(type: type)
      end
    end
  end
end
