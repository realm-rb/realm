# frozen_string_literal: true

module Realm
  class EventRouter
    class Gateway
      # hotfix
      class RuntimeBoundedEventHandler
        def initialize(runtime, handler_class)
          @runtime = runtime
          @handler_class = handler_class
        end

        def call(event)
          @handler_class.(event, runtime: @runtime)
        end

        def queue_suffix
          @handler_class.name.underscore.gsub(%r{/(domain|event_handlers?)}, '').gsub('/', '_')
        end
      end

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
          add_listener(event_type, RuntimeBoundedEventHandler.new(@runtime, handler_class))
        end
      end

      def add_listener(event_type, listener)
        raise NotImplementedError
      end

      def trigger(event_type, attributes = {})
        raise NotImplementedError
      end

      def worker
        nil
      end

      protected

      def create_event(event_type, attributes = {})
        @event_factory.create_event(event_type, **attributes)
      end
    end
  end
end
