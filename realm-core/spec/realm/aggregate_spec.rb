# frozen_string_literal: true

class TestEventBroker
  class << self
    attr_reader :ingest_calls

    def ingest(event, **options)
      (@ingest_calls ||= []) << [event, options]
    end
  end
end

class TestModel
  def transaction
    yield
  end
end

class TestEvent
  def initialize(foo:)
    @foo = foo
  end
end

class TestAggregate < Realm::Aggregate
  root TestModel
  command_methods :do_something

  def do_something(foo)
    apply TestEvent, foo: foo
  end

  def event_broker
    TestEventBroker
  end
end


RSpec.describe Realm::Aggregate do
  describe 'simple command -> event flow' do
    it 'works' do
      TestAggregate.new.do_something('foo')
      ingest_calls = TestEventBroker.ingest_calls
      expect(ingest_calls.size).to eq 1
      expect(ingest_calls[0][0]).to be_a TestEvent
    end
  end
end
