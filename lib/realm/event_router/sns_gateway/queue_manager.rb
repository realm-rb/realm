# frozen_string_literal: true

require 'aws-sdk-sqs'
require_relative './queue_adapter'

module Realm
  class EventRouter
    class SNSGateway < Gateway
      class QueueManager
        def initialize(sqs: Aws::SQS::Resource.new)
          @sqs = sqs
        end

        def get(name: nil, arn: nil)
          throw ArgumentError, 'You have to provide name or arn of the queue' unless name || arn

          QueueAdapter.new(@sqs.get_queue_by_name(queue_name: name || arn.split(':')[-1]))
        end

        def provide(queue_name)
          get(name: queue_name)
        rescue Aws::SQS::Errors::NonExistentQueue
          create(queue_name)
        end

        def create(queue_name)
          QueueAdapter.new(@sqs.create_queue(queue_name: queue_name))
        end
      end
    end
  end
end
