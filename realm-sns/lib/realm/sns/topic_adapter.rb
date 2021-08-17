# frozen_string_literal: true

module Realm
  module SNS
    # Provides cleaner SDK over Aws::SNS::Topic
    class TopicAdapter
      class SubscriptionError < Realm::Error
        def initialize(queue_arn, subscription_attributes)
          super("Cannot subscribe SQS queue #{queue_arn} with attributes #{subscription_attributes}")
        end
      end

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
        attributes = subscribe_attributes(event_type)
        @topic.subscribe(protocol: 'sqs', endpoint: queue.arn, attributes: attributes)
      rescue Aws::SNS::Errors::InvalidParameter
        raise SubscriptionError.new(queue.arn, attributes)
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
