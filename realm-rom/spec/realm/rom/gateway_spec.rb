# frozen_string_literal: true

require 'spec_helper'
require 'rom'
require 'realm/rom/gateway'

module RomGatewayTest; end

RSpec.describe Realm::ROM::Gateway do
  describe '#health' do
    subject do
      described_class.new(
        url: 'sqlite::memory',
        root_module: RomGatewayTest,
        class_path: '/tmp',
        migration_path: '/tmp',
      ).tap(&:configure)
    end

    let(:test_connection) { true }
    let(:pending_migrations) { false }
    let(:rom_gateway) do
      double(
        :rom_gateway,
        connection: double(:connection, test_connection: test_connection),
        migrator: double(:migrator, pending?: pending_migrations),
      )
    end

    before do
      expect(::ROM).to receive(:container).and_return(double(:rom_client, gateways: { default: rom_gateway }))
    end

    context 'with no issues' do
      it 'returns green health status' do
        expect(subject.health.code).to eq(:green)
      end
    end

    context 'with connection issue' do
      let(:test_connection) { false }

      it 'returns red health status' do
        health = subject.health
        expect(health.code).to eq(:red)
        expect(health.issues).to include('Cannot connect to db')
      end
    end

    context 'with pending migrations' do
      let(:pending_migrations) { true }

      it 'returns red health status' do
        health = subject.health
        expect(health.code).to eq(:red)
        expect(health.issues).to include('Pending migrations')
      end
    end
  end
end
