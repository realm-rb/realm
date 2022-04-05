# frozen_string_literal: true

module Realm
  class Aggregate
    class EventHandler < Aggregate::ActionHandler
      class << self
        attr_reader :handled_event_classes

        private

        def on(*event_classes)
          @handled_event_classes = event_classes.freeze
        end
      end
    end
  end
end
