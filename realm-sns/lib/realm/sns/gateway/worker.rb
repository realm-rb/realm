# frozen_string_literal: true

module Realm
  module SNS
    class Gateway < Realm::EventRouter::Gateway
      class Worker
        def initialize(queue_map, event_factory:, event_processing_attempts: 3, logger: nil)
          @queue_map = queue_map
          @event_factory = event_factory
          @event_processing_attempts = event_processing_attempts
          @logger = logger || Logger.new($stdout)
          @threads = []
        end

        def start(poller_options: {})
          @signaler = { exiting: false }
          @queue_map.each_pair do |queue, listener|
            @threads << Thread.new { run_poller(queue, listener, @signaler, poller_options) }
          end
          self
        end

        def stop(timeout: 30)
          Thread.new { @logger.info("Stopping worker (timeout: #{timeout}s)") }.join # Cannot log from trap context
          @signaler[:exiting] = true
          join(timeout)
          @threads.clear
          self
        end

        def join(timeout = nil)
          @threads.each { |thread| thread.join(timeout) }
        end

        private

        def run_poller(queue, listener, signaler, options)
          @logger.info("Start polling #{queue.arn}")
          init_poller(queue, signaler, options).poll do |messages, stats|
            log_poller_stats(queue, stats)
            messages.each { |msg| handle_message(listener, msg) }
          end
          @logger.info("Polling stopped #{queue.arn}")
        end

        def init_poller(queue, signaler, options = {})
          Aws::SQS::QueuePoller.new(
            queue.url,
            max_number_of_messages: 10,
            visibility_timeout: 60,
            attribute_names: ['ApproximateReceiveCount'],
            message_attribute_names: ['event_type'],
            before_request: before_request_proc(queue, signaler),
            **options,
          )
        end

        def before_request_proc(queue, signaler)
          proc {
            if signaler[:exiting]
              @logger.info("Stopping polling #{queue.arn}")
              throw :stop_polling
            end
          }
        end

        def log_poller_stats(queue, stats)
          @logger.info(
            message: "Poller #{queue.arn} stats",
            request_count: stats.request_count,
            message_count: stats.received_message_count,
            last_message_received_at: stats.last_message_received_at,
          )
        end

        def handle_message(listener, msg)
          event = message_to_event(msg)
          listener.(event)
        rescue StandardError => e
          log_error(e, event, msg)
          # Picks up the message again after visibility_timeout runs out:
          throw :skip_delete if event && message_receive_count(msg) < @event_processing_attempts
        end

        def message_to_event(msg)
          event_type = msg.message_attributes['event_type'].string_value
          raise 'Message is missing event type' unless event_type

          payload = JSON.parse(msg.body).deep_symbolize_keys
          @event_factory.create_event(event_type, payload)
        end

        def message_receive_count(msg)
          msg.attributes['ApproximateReceiveCount'].to_i
        end

        def log_error(error, event, msg)
          return @logger.fatal("Unexpected message in queue: #{msg}; error: #{error.full_message}") unless event

          attempt = message_receive_count(msg)
          will_retry = attempt < @event_processing_attempts
          log_line = [
            "Processing of event failed type=#{event.type} id=#{event.head.id} attempt=#{attempt},",
            "#{will_retry ? 'will retry' : 'final'}):\n#{error.full_message}",
          ].join(' ')
          @logger.send(will_retry ? :warn : :error, log_line)
        end
      end
    end
  end
end
