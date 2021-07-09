# frozen_string_literal: true

require 'securerandom'
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

      def type
        @type ||= name.demodulize.sub('Event', '').underscore
      end

      protected

      def body_struct(&block)
        attribute(:body, &block)
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
