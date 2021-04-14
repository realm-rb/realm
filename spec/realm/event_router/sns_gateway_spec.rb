# frozen_string_literal: true

require 'spec_helper'
require 'realm/event_router/sns_gateway'
require 'realm/event_handler'
require 'realm/event_factory'
require 'realm/event'
require_relative '../support/runtime_mock'

require 'aws-sdk-core'
require 'aws-sdk-sns'

Aws.config.update(endpoint: ENV.fetch('AWS_ENDPOINT'))

module SNSGatewaySpec
  class SomethingHappenedEvent < Realm::Event
    body_struct do
      attribute :foo do
        attribute :bar, T::Integer
      end
    end
  end

  class SampleHandler < Realm::EventHandler
    inject :event_log

    on :something_happened
    def handle(event)
      event_log << event
    end
  end

  class SampleAnyHandler < Realm::EventHandler
    inject :event_log

    on :any
    def handle(event)
      event_log << event
    end
  end
end

RSpec.describe Realm::EventRouter::SNSGateway do
  def test_event_flow # rubocop:disable Metrics/AbcSize
    worker = subject.worker.start
    subject.trigger(:something_happened, foo: { bar: 123 })
    worker.stop

    expect(event_log.size).to eq(1)
    expect(event_log[0].body.foo.bar).to eq(123)
  end

  let(:topic_arn) { Aws::SNS::Client.new.create_topic(name: 'sample-topic').topic_arn }
  let(:event_log) { [] }
  let(:sqs) { Aws::SQS::Resource.new }
  let(:queue_names) { sqs.queues.map { |q| q.url.sub(%r{^.*/}, '') } }

  subject do
    described_class.new(
      topic_arn: topic_arn,
      event_factory: Realm::EventFactory.new(SNSGatewaySpec),
      runtime: RuntimeMock.new(context: { event_log: event_log }),
      event_processing_attempts: 1,
    )
  end

  after do
    subject.purge!
  end

  context 'with specific event listener' do
    it 'handles events' do
      subject.add_listener(:something_happened, ->(event) { event_log << event })
      test_event_flow
    end
  end

  context 'with any event listener' do
    it 'handles events' do
      subject.add_listener(:any, ->(event) { event_log << event })
      test_event_flow
    end
  end

  context 'with specific event handler class' do
    it 'handles events' do
      subject.register(SNSGatewaySpec::SampleHandler)
      test_event_flow
      expect(queue_names).to include('something_happened-sns_gateway_spec-sample_handler')
    end
  end

  context 'with any event handler class' do
    it 'handles events' do
      subject.register(SNSGatewaySpec::SampleAnyHandler)
      test_event_flow
      expect(queue_names).to include('any-sns_gateway_spec-sample_any_handler')
    end
  end
end
