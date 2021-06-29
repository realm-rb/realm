# frozen_string_literal: true

require 'spec_helper'
require 'realm/event'
require 'realm/runtime'
require 'realm/event_router'
require 'realm/event_router/internal_loop_gateway'

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
  let(:gateways_spec) do
    {
      ns1: { type: :internal_loop, events_module: EventRouterSpec },
      ns2: { type: :internal_loop, events_module: EventRouterSpec, default: true },
    }
  end
  let(:gateway1) { instance_double(Realm::EventRouter::InternalLoopGateway) }
  let(:gateway2) { instance_double(Realm::EventRouter::InternalLoopGateway) }
  subject { described_class.new(gateways_spec, runtime: runtime, prefix: 'test-prefix') }

  before do
    expect(Realm::EventRouter::InternalLoopGateway).to receive(:new)
      .with(hash_including(namespace: :ns1)).and_return(gateway1)
    expect(Realm::EventRouter::InternalLoopGateway).to receive(:new)
      .with(hash_including(namespace: :ns2)).and_return(gateway2)
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
      subject.trigger('ns2/sample', foo: 456)
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
      subject.workers(:ns2, foo: 456)
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

    context 'with domain resolver' do
      let(:domain_resolver) { double(:domain_resolver, all_event_handlers: [:handler1]) }
      subject do
        described_class.new(gateways_spec, runtime: runtime, prefix: 'test-prefix', domain_resolver: domain_resolver)
      end

      it 'triggers auto registration of event handlers' do
        expect(gateway2).to receive(:register).with(:handler1)
        subject.active_queues
      end
    end
  end
end
