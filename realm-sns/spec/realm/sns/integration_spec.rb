# frozen_string_literal: true

require 'realm-core'
require 'realm-sns'
require 'aws-sdk-core'
require 'aws-sdk-sns'
require 'aws-sdk-sqs'

Aws.config.update(endpoint: ENV.fetch('AWS_ENDPOINT'))

module TestIntegrationService
  module Domain
    module Submission
      class PublishCommandHandler < Realm::CommandHandler
        def handle(submission_id:, **)
          trigger(:submission_published, submission_id: submission_id)
        end
      end

      class SampleEventHandler < Realm::EventHandler
        inject :event_log

        on :submission_published
        def handle_submission_published(event)
          event_log << event
        end
      end
    end

    module Events
      class SubmissionPublished < Realm::Event
        body_struct do
          attribute :submission_id, T::Integer
        end
      end
    end
  end
end

RSpec.describe 'Integration of realm SNS with core' do
  let(:event_log) { [] }
  let(:dependencies) { { event_log: event_log } }
  let(:sns) { Aws::SNS::Client.new }
  let(:sqs) { Aws::SQS::Resource.new }
  let(:topic_arn) { sns.create_topic(name: 'sample-topic').topic_arn }
  let(:realm) do
    Realm.setup(
      TestIntegrationService,
      plugins: :sns,
      engine_class: nil,
      prefix: 'integration-test',
      dependencies: dependencies,
      event_gateway: { type: :sns, topic_arn: topic_arn, events_module: TestIntegrationService::Domain::Events },
    ).runtime
  end
  let(:worker) { realm.worker(event_processing_attempts: 1) }

  before do
    worker.start(poller_options: { wait_time_seconds: nil }) # disable wait time to speed up test
  end

  after do
    worker.stop
    sqs.queues.each(&:delete)
    sns.delete_topic(topic_arn: topic_arn)
  end

  it 'works for happy path' do
    realm.run('submission.publish', submission_id: 123)

    wait_for do
      event_log.size == 1
    end
    expect(event_log[0]).to be_a(TestIntegrationService::Domain::Events::SubmissionPublished)
    expect(event_log[0].body.submission_id).to eq(123)
  end
end
