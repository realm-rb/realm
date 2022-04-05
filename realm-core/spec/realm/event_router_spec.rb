# frozen_string_literal: true

module EventRouterSpec
  class Ns1SampleHandler < Realm::EventHandler
    namespace :ns1
  end

  class SampleHandler < Realm::EventHandler
  end
end

RSpec.describe Realm::EventRouter do
  let(:stack) { [] }
  let(:runtime) { Realm::Runtime.new(stack: stack) }
  let(:gateway1) { Realm::InternalEventLoop::Gateway.new(event_factory: event_factory, namespace: :ns1) }
  let(:gateway2) { Realm::InternalEventLoop::Gateway.new(event_factory: event_factory) }
  let(:event_factory) { Realm::EventFactory.new(EventRouterSpec) }

  subject { described_class.new(runtime: runtime, prefix: 'test-prefix') }

  before do
    subject.register_gateway(gateway1)
    subject.register_gateway(gateway2)
  end

  describe '#register' do
    it 'registers event handler to gateway corresponding to handler namespace' do
      expect(gateway1).to receive(:register).with(EventRouterSpec::Ns1SampleHandler)
      subject.register(EventRouterSpec::Ns1SampleHandler)
    end

    it 'registers event handler to default gateway if no handler namespace is specified' do
      expect(gateway2).to receive(:register).with(EventRouterSpec::SampleHandler)
      subject.register(EventRouterSpec::SampleHandler)
    end
  end

  describe '#add_listener' do
    it 'adds listener on gateway for corresponding namespace' do
      expect(gateway1).to receive(:add_listener).with(:event_type1, :listener1)
      subject.add_listener(:event_type1, :listener1, namespace: :ns1)
    end

    it 'adds listener on default gateway if no namespace is specified' do
      expect(gateway2).to receive(:add_listener).with(:event_type2, :listener2)
      subject.add_listener(:event_type2, :listener2)
    end
  end

  describe '#trigger' do
    it 'triggers event on gateway for corresponding namespace' do
      expect(gateway1).to receive(:trigger).with('sample', foo: 123)
      subject.trigger('ns1/sample', foo: 123)

      expect(gateway2).to receive(:trigger).with('sample', foo: 456)
      subject.trigger('sample', foo: 456)
    end

    it 'triggers event on default gateway if no namespace is specified' do
      expect(gateway2).to receive(:trigger).with(:sample, foo: 123)
      subject.trigger(:sample, foo: 123)
    end

    it 'triggers scoped events' do
      expect(gateway2).to receive(:trigger).with('sample.crated', foo: 123)
      subject.trigger('sample.crated', foo: 123)
    end
  end

  describe '#workers' do
    it 'calls worker method on gateway for corresponding namespace' do
      expect(gateway1).to receive(:worker).with(foo: 123)
      subject.workers(:ns1, foo: 123)

      expect(gateway2).to receive(:worker).with(foo: 456)
      subject.workers(:default, foo: 456)
    end

    it 'calls worker method on all gateways if no namespace is specified' do
      expect(gateway1).to receive(:worker).with(foo: 123)
      expect(gateway2).to receive(:worker).with(foo: 123)
      subject.workers(foo: 123)
    end
  end

  describe '#active_queues' do
    before do
      expect(gateway1).to receive(:queues).and_return([:queue1])
      expect(gateway2).to receive(:queues).and_return([:queue2])
    end

    it 'collects queues from all gateways' do
      expect(subject.active_queues).to eq(%i[queue1 queue2])
    end

    context 'for gateways without handlers registration on init' do
      let(:gateway2) do
        Class.new(Realm::InternalEventLoop::Gateway) do
          register_handlers_on_init false
        end.new(event_factory: event_factory)
      end
      let(:handler1) { Class.new(Realm::EventHandler) }
      let(:domain_resolver) { double(:domain_resolver, all_event_handlers: [handler1]) }
      subject do
        described_class.new(runtime: runtime, prefix: 'test-prefix', domain_resolver: domain_resolver)
      end

      it 'triggers auto registration of event handlers' do
        expect(gateway2).to receive(:register).with(handler1)
        subject.active_queues
      end
    end
  end
end
