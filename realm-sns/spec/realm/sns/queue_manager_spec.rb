# frozen_string_literal: true

RSpec.describe Realm::SNS::QueueManager do
  let(:sqs) { Aws::SQS::Resource.new }
  let(:queue_names) { sqs.queues.map { |q| q.url.sub(%r{^.*/}, '') } }

  subject { described_class.new(prefix: 'test_prefix') }

  after do
    sqs.queues.each(&:delete)
  end

  describe '#get' do
    let!(:existing_queue) { sqs.create_queue(queue_name: 'test_prefix-sample_queue') }

    it 'returns queue by name' do
      queue = subject.get(name: 'sample_queue')
      expect(queue).to be_a Realm::SNS::QueueAdapter
      expect(queue.url).to eq existing_queue.url
    end

    it 'returns queue by arn' do
      queue = subject.get(arn: existing_queue.attributes['QueueArn'])
      expect(queue).to be_a Realm::SNS::QueueAdapter
      expect(queue.url).to eq existing_queue.url
    end
  end

  describe '#create' do
    it 'creates prefixed queue' do
      queue = subject.create('sample_queue')
      expect(queue).to be_a Realm::SNS::QueueAdapter
      expect(sqs.get_queue_by_name(queue_name: 'test_prefix-sample_queue').url).to eq queue.url
    end
  end

  describe '#provide' do
    let!(:existing_queue) { sqs.create_queue(queue_name: 'test_prefix-sample_queue') }

    it 'retrieves queue if exists' do
      queue = subject.provide('sample_queue')
      expect(queue).to be_a Realm::SNS::QueueAdapter
      expect(sqs.get_queue_by_name(queue_name: 'test_prefix-sample_queue').url).to eq existing_queue.url
    end

    it 'creates queue if does not exist' do
      queue = subject.provide('another_queue')
      expect(queue).to be_a Realm::SNS::QueueAdapter
      expect(sqs.get_queue_by_name(queue_name: 'test_prefix-another_queue').url).to eq queue.url
    end
  end

  describe '#cleanup' do
    let!(:used_queue) { subject.create('used_queue') }
    let!(:empty_abandoned_queue) { subject.create('empty_abandoned_queue') }
    let!(:abandoned_queue) do
      subject.create('abandoned_queue').tap do |queue|
        queue.send_message(message_body: 'sample body')
      end
    end

    it 'deletes empty queues which are not skipped' do
      expect { subject.cleanup(except: used_queue) }.to change { sqs.queues.to_a.size }.from(3).to(2)
      expect(queue_names).to include('test_prefix-used_queue', 'test_prefix-abandoned_queue')
    end

    it 'refuses to cleanup without prefix' do
      expect { described_class.new.cleanup(except: used_queue) }.to raise_error(
        Realm::SNS::QueueManager::CleanupWithoutPrefix,
      )
    end
  end
end
