# frozen_string_literal: true

require 'rom-sql'
require 'realm/persistence'

module Realm
  module ROM
    class ReadOnlyRelationWrapper
      FORBIDDEN_METHODS = (::ROM::SQL::Relation::Writing.instance_methods(false) + [:command]).freeze

      def initialize(relation)
        @relation = relation
      end

      def method_missing(symbol, *args)
        raise Persistence::RelationIsReadOnly, @relation if FORBIDDEN_METHODS.include?(symbol)

        @relation.send(symbol, *args)
      end

      def respond_to_missing?(symbol)
        !FORBIDDEN_METHODS.include?(symbol) && @relation.respond_to?(symbol)
      end
    end
  end
end
