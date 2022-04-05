# frozen_string_literal: true

module AggregateSpec
  class TestBroker
    class << self
      attr_reader :ingest_calls

      def apply(event, **options)
        (@ingest_calls ||= []) << [event, options]
      end
    end
  end

  class User
    attr_accessor :name

    def transaction
      yield
    end
  end

  class UserNameChanged
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end

  class UserAggregate < Realm::Aggregate
    root User

    def change_name(name)
      emit UserNameChanged, name: name
    end

    on UserNameChanged do |root, event|
      root.name = event.name
    end

    private

    def event_broker
      TestBroker
    end
  end

  RSpec.describe Realm::Aggregate do
    context 'blank instance' do
      subject { UserAggregate.new }

      it 'handles external event' do
        event = UserNameChanged.new(name: 'value1')
        subject.apply(event)
        expect(subject.root.name).to eq 'value1'
      end

      it 'handles simple command -> event flow' do
        subject.change_name('value1')
        ingest_calls = TestBroker.ingest_calls
        expect(ingest_calls.size).to eq 1
        expect(ingest_calls[0][0]).to be_a UserNameChanged
        expect(ingest_calls[0][0].name).to eq 'value1'
        expect(subject.root.name).to eq 'value1'
      end
    end

    describe '.root' do
      it 'registers root class' do
        klass = Class.new(Realm::Aggregate) do
          root User
        end
        expect(klass.new.root).to be_a User
      end

      it 'registers root class with alias' do
        klass = Class.new(Realm::Aggregate) do
          root User, as: :my_model
        end
        aggregate = klass.new
        expect(aggregate.my_model).to be_a User
        expect(aggregate.root).to eq aggregate.my_model
      end
    end
  end
end
