# frozen_string_literal: true

module Realm
  class Aggregate
    class Stale < Error
      def initialize(expected, current, msg: "Version is older - expected: #{expected}, current: #{current}")
        super(msg)
      end
    end

    class Outran < Error # maybe better word?
      def initialize(expected, current, msg: "Version is newer - expected: #{expected}, current: #{current}")
        super(msg)
      end
    end

    extend ClassMethods
    include Mixins::DependencyInjection

    # inject EventBroker, static: true
    attr_reader :root

    def initialize(root = new_root)
      self.class.discover
      @root = root
    end

    private

    def apply(event, **attributes)
      event = event.new(**attributes) if event.is_a?(Class)
      event_broker.ingest(event, sync_handlers: self.class.event_handlers)
    end

    def new_root
      self.class.root_class.new
    end

    def event_broker
      raise 'Event broker is not injected'
    end
  end
end
