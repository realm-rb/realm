# frozen_string_literal: true

module Realm
  class ActionHandler
    # Tuple of label and value
    class Result < Array
      def self.[](first, second = nil)
        return new(first, second).freeze if first.is_a?(Symbol) || first.is_a?(Realm::Event)

        new(second || :ok, first).freeze
      end

      def label
        self[0]
      end

      def event
        label if label.is_a?(Realm::Event)
      end

      def value
        self[1]
      end

      private

      def initialize(label, value)
        super([label, value])
      end
    end
  end
end
