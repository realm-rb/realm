# frozen_string_literal: true

require 'rom'

module Realm
  class Persistence
    class Gateway
      def self.configure(**options)
        new(**options).tap(&:configure)
      end

      def method_missing(...)
        @client.send(...)
      end

      def respond_to_missing?(...)
        @client.respond_to?(...)
      end
    end
  end
end
