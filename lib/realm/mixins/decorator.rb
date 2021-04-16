# frozen_string_literal: true

module Realm
  module Mixins
    module Decorator
      def self.[](decorated) # rubocop:disable Metrics/MethodLength
        Module.new do
          def method_missing(...)
            _decorated.send(...)
          end

          def respond_to_missing?(...)
            _decorated.respond_to?(...)
          end

          if decorated.to_s[0] == '@'
            define_method :initialize do |value|
              instance_variable_set(decorated, value)
            end

            define_method :_decorated do
              instance_variable_get(decorated)
            end
          else
            define_method :_decorated do
              send(decorated)
            end
          end
        end
      end
    end
  end
end
