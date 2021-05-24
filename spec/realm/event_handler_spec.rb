# frozen_string_literal: true

require 'spec_helper'
require 'realm/runtime'
require 'realm/container'
require 'realm/event'
require 'realm/event_handler'
require 'realm/domain_resolver'

module FooEvents
  class Foo < Realm::Event; end
  class Bar < Realm::Event; end

  class BarWithBody < Realm::Event
    body_struct do
      attribute :value, T::Integer
    end
  end
end

class ZooEvent < Realm::Event; end

class SampleEventHandler < Realm::EventHandler
  inject :stack

  on :bar
  def handle(_event)
    stack << 'called handle'
  end

  on 'zoo'
  def handle_another(_event)
    helper
    stack << 'called handle_another'
  end

  def helper
    stack << 'called helper'
  end
end

class NotNamespacedEventHandler < Realm::EventHandler
  inject :stack

  on :bar
  def handle(_event)
    stack << 'called handle'
  end
end

class MultipleHandleMethodsEventHandler < Realm::EventHandler
  inject :stack

  on :zoo
  def handle(_event)
    stack << 'called handle'
  end

  on 'zoo'
  def handle_another(_event)
    stack << 'called handle_another'
  end
end

class MultipleTriggersEventHandler < Realm::EventHandler
  inject :stack

  on :zoo, 'bar'
  def handle(event)
    stack << "handle #{event.class}"
  end
end

class SubsequentTriggerEventHandler < Realm::EventHandler
  inject :stack

  on :foo
  def handle(_event)
    trigger :bar, attr1: 'value1'
  end
end

class BlockStyleEventHandler < Realm::EventHandler
  inject :stack

  on :bar do |event|
    stack << "handle #{event.class}"
  end
end

class ShorthandEventHandler < Realm::EventHandler
  on :bar_with_body, run: :command1
end

RSpec.describe Realm::EventHandler do
  let(:stack) { [] }
  let(:container) { Realm::Container[stack: stack] }
  let(:runtime) { Realm::Runtime.new(container) }

  before do
    container.register(Realm::DomainResolver)
  end

  describe '.call' do
    it 'calls correct event handler methods' do
      SampleEventHandler.(FooEvents::Bar.new, runtime: runtime)
      expect(stack.last).to eq('called handle')

      SampleEventHandler.(ZooEvent.new, runtime: runtime)
      expect(stack.last(2)).to eq(['called helper', 'called handle_another'])
    end

    it 'fallbacks to not namespaced trigger' do
      NotNamespacedEventHandler.(FooEvents::Bar.new, runtime: runtime)
      expect(stack.last).to eq('called handle')
    end

    it 'supports multiple handlers for the same trigger' do
      MultipleHandleMethodsEventHandler.(ZooEvent.new, runtime: runtime)
      expect(stack.last(2)).to eq(['called handle', 'called handle_another'])
    end

    it 'supports multiple triggers for the same handler' do
      MultipleTriggersEventHandler.(FooEvents::Bar.new, runtime: runtime)
      MultipleTriggersEventHandler.(ZooEvent.new, runtime: runtime)
      expect(stack.last(2)).to eq(['handle FooEvents::Bar', 'handle ZooEvent'])
    end

    it 'supports block style definition' do
      BlockStyleEventHandler.(FooEvents::Bar.new, runtime: runtime)
      expect(stack.last).to eq('handle FooEvents::Bar')
    end

    it 'supports shorthand style definition' do
      expect_any_instance_of(Realm::Dispatcher).to receive(:run).with('command1', value: 11)
      ShorthandEventHandler.(FooEvents::BarWithBody.new(value: 11), runtime: runtime)
    end
  end

  describe '#trigger' do
    it 'triggers subsequent event' do
      foo = FooEvents::Foo.new
      expected_head = { origin: 'SubsequentTriggerEventHandler#handle' }
      expect(runtime).to receive(:trigger).with(:bar, cause: foo, head: expected_head, attr1: 'value1')

      SubsequentTriggerEventHandler.bind_runtime(runtime).(foo)
    end
  end
end
