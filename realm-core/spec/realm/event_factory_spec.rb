# frozen_string_literal: true

require 'dry-struct'

module EventFactorySpecEvents
  KeyType = Realm::Types::String
  MyStruct = Dry.Struct(text: Realm::Types::String)

  class Foo < Realm::Event
    body_struct do
      attribute :number, T::Integer
    end
  end

  class BarEvent < Realm::Event
    body_struct do
      attributes_from MyStruct
      attribute? :key, KeyType
    end

    class V2 < Realm::Event
      type 'bar.v2'

      body_struct do
        attributes_from BarEvent::Body
        attribute :foo, T::Integer
      end
    end
  end

  class ScopedFoo < Foo
    def self.type
      'custom_scope.foo'
    end
  end
end

RSpec.describe Realm::EventFactory do
  describe '#create_event' do
    subject { described_class.new(EventFactorySpecEvents) }
    let(:foo_event) { subject.create_event(:foo, number: 1) }
    let(:bar_event) { subject.create_event(:bar, key: 'K12', text: 'hi') }

    it 'instantiates event' do
      expect(foo_event).to be_a EventFactorySpecEvents::Foo
      expect(foo_event.body.number).to eq 1

      expect(bar_event).to be_a EventFactorySpecEvents::BarEvent
      expect(bar_event.body.text).to eq 'hi'
      expect(bar_event.body.key).to eq 'K12'
    end

    context 'with correlate option' do
      let(:bar_event) { subject.create_event(:bar, text: 'hi', correlate: foo_event) }

      it 'correlates events' do
        expect(bar_event.head.correlation_id).to eq foo_event.head.correlation_id
      end
    end

    context 'with cause option' do
      let(:bar_event) { subject.create_event(:bar, text: 'hi', cause: foo_event) }

      it 'correlates events and set cause' do
        expect(bar_event.head.correlation_id).to eq foo_event.head.correlation_id
        expect(bar_event.head.cause_event_id).to eq foo_event.head.id
      end
    end

    context 'with customized event type' do
      it 'creates correct event instance' do
        event = subject.create_event('custom_scope.foo', number: 2)
        expect(event).to be_a EventFactorySpecEvents::ScopedFoo
        expect(event.body.number).to eq 2
      end
    end

    context 'with nested event type' do
      it 'creates correct event instance' do
        event = subject.create_event('bar.v2', text: 'hi', foo: 2)
        expect(event).to be_a EventFactorySpecEvents::BarEvent::V2
        expect(event.body.text).to eq 'hi'
        expect(event.body.foo).to eq 2
      end
    end
  end
end
