# frozen_string_literal: true

module Realm
  class Aggregate
    class ActionHandler
      class Outbox
        include Enumerable

        def initialize(*events)
          @events = events
        end

        def <<(event)
          @events << event
        end

        def each(&block)
          @events.each(&block)
        end

        def empty?
          @events.empty?
        end
      end

      include Mixins::DependencyInjection

      attr_reader :root

      def self.call(root, ...)
        new.(root, ...)
      end

      def initialize(&block)
        @handler_block = block
      end

      def call(root, ...)
        @outbox = Outbox.new # FIX: not thread safe
        root.transaction do
          handle(root, ...)
        end
        @outbox
      end

      def handle(root, *args, **kwargs)
        return @handler_block.(root, *args, applier: method(:apply), **kwargs) if @handler_block

        raise NotImplementedError
      end

      private

      def apply(event, **attributes)
        event = event.new(**attributes) if event.is_a?(Class)
        @outbox << event
      end
    end
  end
end
