# frozen_string_literal: true

class TestEventBroker
  class << self
    attr_reader :ingest_calls

    def apply(event, **options)
      (@ingest_calls ||= []) << [event, options]
    end
  end
end

class TestModel
  attr_accessor :bar

  def transaction
    yield
  end
end

class TestEvent
  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end
end

class TestAggregate < Realm::Aggregate
  root TestModel
  command_methods :do_something

  def do_something(foo)
    emit TestEvent, foo: foo
  end

  def event_broker
    TestEventBroker
  end

  on TestEvent do |root, event|
    root.bar = event.foo
  end
end


RSpec.describe Realm::Aggregate do
  context 'blank instance' do
    subject { TestAggregate.new }

    it 'holds root instance' do
      expect(subject.root).to be_a TestModel
    end

    it 'handles external event' do
      event = TestEvent.new(foo: 'value1')
      subject.apply(event)
      expect(subject.root.bar).to eq 'value1'
    end

    it 'handles simple command -> event flow' do
      subject.do_something('value1')
      ingest_calls = TestEventBroker.ingest_calls
      expect(ingest_calls.size).to eq 1
      expect(ingest_calls[0][0]).to be_a TestEvent
      expect(ingest_calls[0][0].foo).to eq 'value1'
      expect(subject.root.bar).to eq 'value1'
    end
  end
end
