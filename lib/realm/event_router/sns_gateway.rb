# frozen_string_literal: true

require 'securerandom'
require 'active_support/core_ext/string'

require 'realm/event_handler'
require_relative './gateway'
require_relative './sns_gateway/queue_manager'
require_relative './sns_gateway/topic_adapter'
require_relative './sns_gateway/worker'

module Realm
  class EventRouter
    class SNSGateway < Gateway
      def initialize(topic_arn:, queue_prefix: nil, event_processing_attempts: 3, **)
        super
        @topic = TopicAdapter.new(topic_arn)
        @queue_prefix = queue_prefix
        @event_processing_attempts = event_processing_attempts
        @queue_map = {}
      end

      def add_listener(event_type, listener, queue_arn: nil)
        queue = queue_arn ? queue_manager.get(arn: queue_arn) : provide_queue(event_type, listener)
        @queue_map[queue] = listener
      end

      def trigger(event_type, attributes = {})
        create_event(event_type, attributes).tap { |event| @topic.publish(event_type, event.to_json) }
      end

      def worker(**options)
        @worker ||= Worker.new(
          @queue_map,
          event_factory: @event_factory,
          logger: @runtime && @runtime.context[:logger],
          event_processing_attempts: @event_processing_attempts,
          **options,
        )
      end

      # Cleans up empty abandoned queues and subscriptions (for cases when event handler was removed or renamed)
      def cleanup
        queue_manager.cleanup(except: @queue_map.values)
      end

      private

      def provide_queue(event_type, listener)
        queue_name = [event_type, queue_suffix(listener)].join('-')
        queue = queue_manager.provide(queue_name)
        @topic.subscribe(event_type, queue)
        queue
      end

      def queue_manager
        @queue_manager ||= QueueManager.new(prefix: @queue_prefix)
      end

      def queue_suffix(listener)
        listener.try(:identifier) || SecureRandom.alphanumeric(16)
      end
    end
  end
end
