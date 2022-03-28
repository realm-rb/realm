# frozen_string_literal: true

module Realm
  class EventFactory
    def initialize(events_module)
      @events_module = events_module
      @event_class_map = collect_event_classes(events_module)
    end

    def create_event(event_type, correlate: nil, cause: nil, **attributes)
      head = enhance_head(attributes.fetch(:head, {}), correlate: correlate, cause: cause)
      body = attributes.fetch(:body, attributes.except(:head))

      event_class_for(event_type).new(head: head, body: body)
    end

    def event_class_for(event_type)
      return event_type if event_type.respond_to?(:new)

      @event_class_map.fetch(event_type.to_s) do
        raise EventClassMissing.new(event_type, @events_module)
      end
    end

    private

    def collect_event_classes(root_module)
      root_module.constants(false).each_with_object({}) do |const_sym, all|
        const = root_module.const_get(const_sym)
        next unless const.is_a?(Module)

        all[const.type] = const if const < Event
        all.merge!(collect_event_classes(const))
      end
    end

    def enhance_head(head, correlate:, cause:)
      head[:correlation_id] = correlate.head.correlation_id if correlate
      if cause.is_a?(Event)
        head[:cause_event_id] = cause.head.id
        head[:correlation_id] ||= cause.head.correlation_id
      elsif cause
        head[:cause] = cause
      end
      head
    end
  end
end
