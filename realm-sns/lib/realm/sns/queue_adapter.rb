# frozen_string_literal: true

module Realm
  module SNS
    # Provides cleaner SDK over Aws::SQS::Queue
    class QueueAdapter
      include Mixins::Decorator[:@queue]

      def arn
        @queue.attributes['QueueArn']
      end

      def allow_send_messages(source_arn)
        @queue.set_attributes(attributes: {
                                'Policy' => {
                                  'Version' => '2012-10-17',
                                  'Statement' => policy_statement(source_arn),
                                }.to_json,
                              })
      end

      def publish(event_type, message)
        @queue.send_message(
          message_body: message,
          message_attributes: { 'event_type' => { data_type: 'String', string_value: event_type.to_s } },
        )
      end

      def empty?
        attributes.slice(
          'ApproximateNumberOfMessages',
          'ApproximateNumberOfMessagesDelayed',
          'ApproximateNumberOfMessagesNotVisible',
        ).all? { |_, val| val.to_i.zero? }
      end

      private

      def policy_statement(source_arn)
        {
          'Effect' => 'Allow',
          'Principal' => { 'AWS' => '*' },
          'Action' => 'sqs:SendMessage',
          'Resource' => arn,
          'Condition' => {
            'ArnEquals' => { 'aws:SourceArn' => source_arn },
          },
        }
      end
    end
  end
end
