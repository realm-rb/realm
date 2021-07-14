# frozen_string_literal: true

require 'dry-struct'
require 'dry-schema'

module Realm
  class Struct < Dry::Struct
    class << self
      def to_dry_schema(type: :schema)
        keys = schema.type.keys

        Dry::Schema.send(schema_type_to_method(type)) do
          keys.each do |key|
            param = key.required? ? required(key.name) : optional(key.name)

            if key.type.constructor_type == Dry::Types::Array::Constructor # array type
              member = key.type.member
              param.array(member.respond_to?(:to_dry_schema) ? member.to_dry_schema(type: type) : member)
            elsif key.respond_to?(:to_dry_schema) # realm struct
              param.hash(key.to_dry_schema(type: type))
            else
              param.send(key.required? ? :filled : :maybe, key.type)
            end
          end
        end
      end

      private

      def schema_type_to_method(type)
        case(type)
        when :schema
          :define
        when :params
          :Params
        when :json
          :JSON
        else
          fail "Not supported schema type #{type}"
        end
      end
    end
  end
end
