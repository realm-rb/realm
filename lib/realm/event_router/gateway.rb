# frozen_string_literal: true

module Realm
  class EventRouter
    class Gateway
      def self.auto_register_on_init
        false
      end

      def initialize(event_factory:, namespace: :default, runtime: nil, **)
        @namespace = namespace
        @event_factory = event_factory
        @runtime = runtime
      end

      def register(handler_class)
        handler_class.event_types.each do |event_type|
          add_listener(event_type, handler_class.bind_runtime(@runtime))
        end
      end

      def add_listener(event_type, listener)
        raise NotImplementedError
      end

      def trigger(event_type, attributes = {})
        raise NotImplementedError
      end

      def worker(*)
        nil
      end

      def cleanup
        # do nothing
      end

      def queues
        []
      end

      protected

      def create_event(event_type, attributes = {})
        @event_factory.create_event(event_type, **attributes)
      end
    end
  end
end
