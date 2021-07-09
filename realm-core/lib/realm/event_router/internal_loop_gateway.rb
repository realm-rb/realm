# frozen_string_literal: true

module Realm
  class EventRouter
    class InternalLoopGateway < Gateway
      def self.auto_register_on_init
        true
      end

      def initialize(isolated: false, **)
        super
        @listener_map = {}
        @isolated = isolated
        gateways << self
      end

      def add_listener(event_type, listener)
        (@listener_map[event_type.to_sym] ||= []) << listener
      end

      def trigger(event_type, attributes = {})
        create_event(event_type, attributes).tap do |event|
          gateways.each { |gateway| gateway.handle(event_type, event) }
        end
      end

      def purge!
        gateways.clear
      end

      protected

      def handle(event_type, event)
        find_listeners(event_type).each { |listener| listener.(event) }
      end

      private

      def find_listeners(event_type)
        @listener_map.fetch_values(event_type.to_sym, :any) { [] }.flatten
      end

      def gateways
        @isolated ? (@gateways ||= []) : (@@gateways ||= []) # rubocop:disable Style/ClassVars
      end
    end
  end
end
