# frozen_string_literal: true

module AggregateSpec
  class MyEventBroker
    class << self
      attr_reader :ingest_calls

      def apply(event, **options)
        (@ingest_calls ||= []) << [event, options]
      end
    end
  end

  class MyModel
    attr_accessor :bar

    def transaction
      yield
    end
  end

  class MyEvent
    attr_reader :foo

    def initialize(foo:)
      @foo = foo
    end
  end

  class MyAggregate < Realm::Aggregate
    root MyModel

    def do_something(foo)
      emit MyEvent, foo: foo
    end

    on MyEvent do |root, event|
      root.bar = event.foo
    end

    private

    def event_broker
      MyEventBroker
    end
  end

  RSpec.describe Realm::Aggregate do
    context 'blank instance' do
      subject { MyAggregate.new }

      it 'handles external event' do
        event = MyEvent.new(foo: 'value1')
        subject.apply(event)
        expect(subject.root.bar).to eq 'value1'
      end

      it 'handles simple command -> event flow' do
        subject.do_something('value1')
        ingest_calls = MyEventBroker.ingest_calls
        expect(ingest_calls.size).to eq 1
        expect(ingest_calls[0][0]).to be_a MyEvent
        expect(ingest_calls[0][0].foo).to eq 'value1'
        expect(subject.root.bar).to eq 'value1'
      end
    end

    describe '.root' do
      it 'registers root class' do
        klass = Class.new(Realm::Aggregate) do
          root MyModel
        end
        expect(klass.new.root).to be_a MyModel
      end

      it 'registers root class with alias' do
        klass = Class.new(Realm::Aggregate) do
          root MyModel, as: :my_model
        end
        aggregate = klass.new
        expect(aggregate.my_model).to be_a MyModel
        expect(aggregate.root).to eq aggregate.my_model
      end
    end
  end
end
