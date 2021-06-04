# frozen_string_literal: true

require 'aws-sdk-sqs'
require 'realm/error'
require_relative './queue_adapter'

module Realm
  module SNS
    class Gateway < Realm::EventRouter::Gateway
      class QueueManager
        class QueueNameTooLong < Realm::Error
          def initialize(name, msg: "Queue name '#{name}' cannot be longer than 80 characters, " \
                                    "please provide custom EventHandler identifier if it's auto generated")
            super(msg)
          end
        end

        CleanupWithoutPrefix = Realm::Error[
          'Cleaning up queues without prefix is not allowed, it can lead to deleting queues from other apps']

        def initialize(prefix: nil, sqs: Aws::SQS::Resource.new)
          @prefix = prefix
          @sqs = sqs
        end

        def get(name: nil, arn: nil)
          throw ArgumentError, 'You have to provide name or arn of the queue' unless name || arn

          QueueAdapter.new(@sqs.get_queue_by_name(queue_name: name ? prefix_name(name) : arn.split(':')[-1]))
        end

        def create(queue_name)
          name = prefix_name(queue_name)
          raise QueueNameTooLong, name if name.size > 80

          QueueAdapter.new(@sqs.create_queue(queue_name: name))
        end

        def provide(queue_name)
          get(name: queue_name)
        rescue Aws::SQS::Errors::NonExistentQueue
          create(queue_name)
        end

        def cleanup(except: [])
          raise CleanupWithoutPrefix unless @prefix

          except_urls = Array(except).map(&:url)
          @sqs.queues(queue_name_prefix: @prefix).each do |queue|
            next if except_urls.include?(queue.url)

            queue.delete if QueueAdapter.new(queue).empty?
          end
        end

        private

        def prefix_name(name)
          [@prefix, name].compact.join('-')
        end
      end
    end
  end
end
