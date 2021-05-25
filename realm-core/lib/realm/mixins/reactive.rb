# frozen_string_literal: true

require 'realm/error'

module Realm
  module Mixins
    module Reactive
      protected

      def run(command, params = {})
        parts = command.to_s.split('.')
        parts.prepend(aggregate) if parts.size == 1 && respond_to?(:aggregate) && aggregate
        @runtime.run(parts.join('.'), params.to_h)
      end

      def trigger(event_type, attributes = {})
        attributes = attributes.to_h
        head = { origin: origin(caller_locations(1, 1)) }.merge(attributes.fetch(:head, {}))
        final_attrs = attributes.merge(head: head)
        final_attrs[:cause] ||= context[:cause] if context.key?(:cause)
        @runtime.trigger(event_type, final_attrs)
      end

      private

      # Detects the class and method from which this event is triggered
      def origin(backtrace)
        [self.class.name, backtrace[0].to_s.match(/`([^']+)'/)&.then { |m| "##{m[1]}" }].join
      end
    end
  end
end
