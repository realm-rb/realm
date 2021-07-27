# frozen_string_literal: true

require 'securerandom'
require 'dry/core/constants'
require 'dry-struct'

module Realm
  class Event < Dry::Struct
    T = Realm::Types

    transform_keys(&:to_sym)

    attribute :head do
      attribute :id, T::Strict::String
      attribute :triggered_at, T::JSON::Time
      attribute? :version, T::Coercible::String
      attribute? :origin, T::Strict::String
      attribute :correlation_id, T::Strict::String
      attribute? :cause_event_id, T::Strict::String
      attribute? :cause, T::Strict::String
    end

    class << self
      def new(attributes = {})
        head = {
          id: SecureRandom.uuid,
          correlation_id: SecureRandom.uuid,
          triggered_at: Time.now,
          version: 1, # until we need breaking change (anything except adding attribute) all events are version 1
        }.merge(attributes.fetch(:head, {}))
        body = attributes[:body] || attributes.except(:head)
        super({ head: head }.merge(body.empty? ? {} : { body: body }))
      end

      def type(value = :not_provided)
        @type = value unless value == :not_provided
        @type ||= name.demodulize.sub('Event', '').underscore
      end

      def attributes_with_meta
        @attributes_with_meta ||= collect_attributes_with_meta(schema.key(:body).type)
      end

      protected

      def body_struct(type = Dry::Core::Constants::Undefined, &block)
        attribute(:body, type, &block)
      end

      private

      def collect_attributes_with_meta(thing, path = []) # rubocop:disable Metrics/AbcSize
        if thing.respond_to?(:schema) # struct
          thing.schema.keys.reduce({}) do |memo, key|
            memo.merge(collect_attributes_with_meta(key.type, path + [key.name]))
          end
        elsif thing.constructor_type == Dry::Types::Array::Constructor # array
          collect_attributes_with_meta(thing.type.member, path + [:[]])
        else
          thing.meta.present? ? { path => thing.meta } : {}
        end
      end
    end

    def type
      self.class.type
    end

    def to_json(*args)
      JSON.generate(to_h, *args)
    end
  end
end
