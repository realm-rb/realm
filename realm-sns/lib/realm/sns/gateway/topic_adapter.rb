# frozen_string_literal: true

require 'aws-sdk-sns'

module Realm
  module SNS
    class Gateway < Realm::EventRouter::Gateway
      # Provides cleaner SDK over Aws::SNS::Topic
      class TopicAdapter
        def initialize(topic_or_arn)
          @topic = topic_or_arn.is_a?(Aws::SNS::Topic) ? topic_or_arn : Aws::SNS::Resource.new.topic(topic_or_arn)
        end

        def publish(event_type, message)
          @topic.publish(
            message: message,
            message_attributes: { 'event_type' => { data_type: 'String', string_value: event_type.to_s } },
          )
        end

        def subscribe(event_type, queue)
          queue.allow_send_messages(@topic.arn)
          @topic.subscribe(
            protocol: 'sqs',
            endpoint: queue.arn,
            attributes: subscribe_attributes(event_type),
          )
        end

        private

        def subscribe_attributes(event_type)
          attrs = { 'RawMessageDelivery' => true }
          attrs['FilterPolicy'] = { 'event_type' => [event_type] } unless event_type == :any
          attrs.transform_values(&:to_json)
        end
      end
    end
  end
end
