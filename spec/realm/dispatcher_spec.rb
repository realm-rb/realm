# frozen_string_literal: true

require 'realm/dispatcher'
require 'realm/domain_resolver'
require 'realm/query_handler'
require 'realm/command_handler'
require 'realm/error'
require_relative 'support/runtime_mock'

RSpec.describe Realm::Dispatcher do
  let(:domain_resolver) { instance_double(Realm::DomainResolver) }
  let(:handler) { ->(**args) { args } }
  let(:runtime) { nil }
  subject { described_class.new(domain_resolver: domain_resolver, runtime: runtime) }

  describe '#query' do
    it 'dispatches query if handler exist' do
      expect(domain_resolver).to receive(:get_handler_with_action)
        .with(Realm::QueryHandler, :query_name).and_return([handler, :query_name])

      expect(subject.query(:query_name, foo: 123)).to eq(action: :query_name, params: { foo: 123 })
    end

    context 'with missing handler but matching repository name' do
      let(:user_repo) { double(:user_repo, find: nil) }
      let(:context) { { user_repo: user_repo }.with_indifferent_access }
      let(:runtime) { RuntimeMock.new(domain_resolver: domain_resolver, context: context) }

      it 'passes query down to repo query handler adapter' do
        expect(domain_resolver).to receive(:get_handler_with_action)
          .with(Realm::QueryHandler, 'user.find').and_return([nil, nil])
        expect(user_repo).to receive(:find).with(id: 1).and_return(:user1)

        expect(subject.query('user.find', id: 1)).to eq(:user1)
      end
    end

    it 'raises error if handler is missing' do
      expect(domain_resolver).to receive(:get_handler_with_action).and_return([nil, nil])
      expect { subject.query(:missing) }.to raise_error(Realm::QueryHandlerMissing)
    end
  end

  describe '#run' do
    it 'dispatches command if handler exist' do
      expect(domain_resolver).to receive(:get_handler_with_action)
        .with(Realm::CommandHandler, :command_name).and_return([handler, :command_name])

      expect(subject.run(:command_name, foo: 123)).to eq(action: :command_name, params: { foo: 123 })
    end

    it 'raises error if handler is missing' do
      expect(domain_resolver).to receive(:get_handler_with_action).and_return([nil, nil])
      expect { subject.run(:missing) }.to raise_error(Realm::CommandHandlerMissing)
    end
  end

  describe '#run_as_job' do
    it 'dispatches command on background if handler exist' do
      expect(domain_resolver).to receive(:get_handler_with_action)
        .with(Realm::CommandHandler, :command_name).and_return([handler, :command_name])

      subject.run_as_job(:command_name, foo: 123) do |result|
        expect(result).to eq(action: :command_name, params: { foo: 123 })
      end.join
    end

    it 'raises error if handler is missing' do
      expect(domain_resolver).to receive(:get_handler_with_action).and_return([nil, nil])
      expect { subject.run_as_job(:missing) }.to raise_error(Realm::CommandHandlerMissing)
    end
  end
end
