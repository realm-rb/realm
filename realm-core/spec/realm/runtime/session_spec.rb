# frozen_string_literal: true

RSpec.describe Realm::Runtime::Session do
  let(:container) { Realm::Container[foo: 1] }
  let(:domain_resolver) { instance_double(Realm::DomainResolver, all_event_handlers: []) }
  let(:runtime) { Realm::Runtime.new(container) }
  subject { runtime.session(bar: 2) }

  before do
    container.register('Realm::DomainResolver', domain_resolver)
  end

  describe '#context' do
    it 'combines temporary data and runtime context' do
      expect(subject.context[:foo]).to eq(1)
      expect(subject.context[:bar]).to eq(2)
    end
  end

  describe '#session' do
    it 'returns self if passed context is empty' do
      expect(subject.session({})).to eq(subject)
    end

    it 'returns instance of Session if passed context is not empty' do
      expect(Realm::Runtime::Session).to receive(:new).with(subject, { zoo: 3 }).and_call_original
      session = subject.session(zoo: 3)
      expect(session).to be_a(Realm::Runtime::Session)
      expect(session.context[:foo]).to eq(1)
      expect(session.context[:bar]).to eq(2)
      expect(session.context[:zoo]).to eq(3)
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
    let(:event_router) { instance_double(Realm::EventRouter) }
    before do
      container.register('Realm::EventRouter', event_router)
    end

    describe '#trigger' do
      it 'passes the call down to event router' do
        expect(event_router).to receive(:trigger).with(:sample_name, foo: 123).and_return(:result)
        expect(subject.trigger(:sample_name, foo: 123)).to eq(:result)
      end
    end

    describe '#add_listener' do
      it 'passes the call down to event router' do
        expect(event_router).to receive(:add_listener).with(
          :name1, :listener1, namespace: :namespace1
        ).and_return(:result)
        expect(subject.add_listener(:name1, :listener1, namespace: :namespace1)).to eq(:result)
      end
    end

    describe '#worker' do
      it 'calls EventRouter#workers and wrap it into MultiWorker' do
        expect(event_router).to receive(:workers).with(:foo, :bar).and_return([:worker1])
        worker = subject.worker(:foo, :bar)
        expect(worker).to be_a(Realm::MultiWorker)
      end
    end
  end
end
