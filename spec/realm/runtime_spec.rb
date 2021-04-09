# frozen_string_literal: true

require 'spec_helper'
require 'realm/runtime'
require 'realm/runtime/session'
require 'realm/domain_resolver'
require 'realm/dispatcher'
require 'realm/event_router'
require 'realm/multi_worker'
require 'realm/health_status'

RSpec.describe Realm::Runtime do
  let(:context) { { foo: 1 } }
  let(:domain_resolver) { instance_double(Realm::DomainResolver, all_event_handlers: []) }
  subject { described_class.new(domain_resolver: domain_resolver, context: context) }

  describe '#[]' do
    it 'passes the call down to context' do
      expect(subject[:foo]).to eq(1)
    end
  end

  describe '#session' do
    it 'returns self if passed context is empty' do
      expect(subject.session({})).to eq(subject)
    end

    it 'returns instance of Session if passed context is not empty' do
      expect(Realm::Runtime::Session).to receive(:new).with(
        subject, kind_of(Realm::Dispatcher), { bar: 2 }
      ).and_call_original
      session = subject.session(bar: 2)
      expect(session).to be_a(Realm::Runtime::Session)
      expect(session.context).to eq(foo: 1, bar: 2)
    end
  end

  describe '#health' do
    let(:context) do
      {
        foo: double(:component1),
        bar: double(:component2, health: Realm::HealthStatus[:green]),
        zoo: double(:component3, health: Realm::HealthStatus[:yellow]),
      }
    end

    it 'returns combined health status for all components responding to health method' do
      expect(subject.health.code).to eq(:yellow)
    end
  end

  %i[query run run_as_job].each do |method|
    describe "##{method}" do
      it 'passes the call down to dispatcher' do
        expect_any_instance_of(Realm::Dispatcher).to receive(method).with(:sample_name, foo: 123).and_return(:result)
        expect(subject.send(method, :sample_name, foo: 123)).to eq(:result)
      end
    end
  end

  describe '#wait_for_jobs' do
    it 'passes the call down to dispatcher' do
      expect_any_instance_of(Realm::Dispatcher).to receive(:wait_for_jobs).and_return(:result)
      expect(subject.wait_for_jobs).to eq(:result)
    end
  end

  context 'with event gateway configured' do
    let(:event_gateways_config) { { default: { type: :internal_loop, events_module: Module.new } } }
    subject do
      described_class.new(
        domain_resolver: domain_resolver,
        context: context,
        event_gateways_config: event_gateways_config,
      )
    end

    describe '#trigger' do
      it 'passes the call down to event router' do
        expect_any_instance_of(Realm::EventRouter).to receive(:trigger).with(:sample_name, foo: 123).and_return(:result)
        expect(subject.trigger(:sample_name, foo: 123)).to eq(:result)
      end
    end

    describe '#add_listener' do
      it 'passes the call down to event router' do
        expect_any_instance_of(Realm::EventRouter).to receive(:add_listener).with(
          :name1, :listener1, namespace: :namespace1
        ).and_return(:result)
        expect(subject.add_listener(:name1, :listener1, namespace: :namespace1)).to eq(:result)
      end
    end

    describe '#worker' do
      it 'calls EventRouter#workers and wrap it into MultiWorker' do
        expect_any_instance_of(Realm::EventRouter).to receive(:workers).with(:foo, :bar).and_return([:worker1])
        worker = subject.worker(:foo, :bar)
        expect(worker).to be_a(Realm::MultiWorker)
      end
    end
  end
end
