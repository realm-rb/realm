# frozen_string_literal: true

module Realm
  class EventRouter
    class Gateway
      include Mixins::DependencyInjection

      inject Runtime

      attr_reader :namespace

      def self.register_handlers_on_init(value = :not_provided)
        @register_handlers_on_init = value unless value == :not_provided
        @register_handlers_on_init ||= false
      end

      def initialize(event_factory:, namespace: :default, **)
        @namespace = namespace
        @event_factory = event_factory
      end

      def register(handler_class)
        # TODO: validate event_types for existence of matching class
        handler_class.event_types.each do |event_type|
          add_listener(event_type, handler_class.bind_runtime(runtime))
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

      def register_handlers_on_init
        self.class.register_handlers_on_init
      end

      protected

      def create_event(event_type, attributes = {})
        @event_factory.create_event(event_type, **attributes)
      end
    end
  end
end
