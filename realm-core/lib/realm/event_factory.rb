# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'realm/error'
require 'realm/event'

module Realm
  class EventFactory
    def initialize(events_module)
      @events_module = events_module
    end

    def create_event(event_type, correlate: nil, cause: nil, **attributes)
      head = enhance_head(attributes.fetch(:head, {}), correlate: correlate, cause: cause)
      body = attributes.fetch(:body, attributes.except(:head))

      event_class_for(event_type).new(head: head, body: body)
    end

    def event_class_for(event_type)
      return event_type if event_type.respond_to?(:new)

      class_name = "#{@events_module}::#{event_type.to_s.gsub('.', '/').camelize}"
      klass = class_name.safe_constantize || "#{class_name}Event".safe_constantize
      return klass if klass

      raise EventClassMissing.new(event_type, @events_module)
    end

    private

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
