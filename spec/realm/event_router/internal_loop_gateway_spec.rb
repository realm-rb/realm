# frozen_string_literal: true

require 'spec_helper'
require 'realm/event_router/internal_loop_gateway'
require 'realm/event_handler'
require 'realm/event_factory'
require 'realm/event'
require_relative '../support/runtime_mock'

module InternalLoopGatewaySpec
  class SomethingHappenedEvent < Realm::Event
    body_struct do
      attribute :foo do
        attribute :bar, T::Integer
      end
    end
  end

  class SampleHandler < Realm::EventHandler
    inject :event_log

    on :something_happened
    def handle(event)
      event_log << event
    end
  end

  class SampleAnyHandler < Realm::EventHandler
    inject :event_log

    on :any
    def handle(event)
      event_log << event
    end
  end
end

RSpec.describe Realm::EventRouter::InternalLoopGateway do
  def test_event_flow # rubocop:disable Metrics/AbcSize
    gateways[rand(0..1)].trigger(:something_happened, foo: { bar: 123 })

    event_logs.each do |event_log|
      expect(event_log.size).to eq(1)
      expect(event_log[0].body.foo.bar).to eq(123)
    end
  end

  let(:event_logs) { [[], []] }

  after do
    gateways[0].purge!
  end

  context 'with event listener' do
    let(:gateways) do
      event_logs.map { described_class.new(event_factory: Realm::EventFactory.new(InternalLoopGatewaySpec)) }
    end

    it 'handles specific event' do
      gateways.each_with_index { |g, i| g.add_listener(:something_happened, ->(event) { event_logs[i] << event }) }
      test_event_flow
    end

    it 'handles any event' do
      gateways.each_with_index { |g, i| g.add_listener(:any, ->(event) { event_logs[i] << event }) }
      test_event_flow
    end
  end

  context 'with event handler class' do
    let(:gateways) do
      event_logs.map do |el|
        described_class.new(
          event_factory: Realm::EventFactory.new(InternalLoopGatewaySpec),
          runtime: RuntimeMock.new(context: { event_log: el }),
        )
      end
    end

    it 'handles specific event' do
      gateways.each { |g| g.register(InternalLoopGatewaySpec::SampleHandler) }
      test_event_flow
    end

    it 'handles any event' do
      gateways.each { |g| g.register(InternalLoopGatewaySpec::SampleAnyHandler) }
      test_event_flow
    end
  end
end
