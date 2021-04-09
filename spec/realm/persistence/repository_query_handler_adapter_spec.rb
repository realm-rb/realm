# frozen_string_literal: true

require 'spec_helper'
require 'realm/persistence/rom/repository'
require 'realm/persistence/repository_query_handler_adapter'

module RepositoryQueryHandlerAdapterSpec
  class Users < ROM::Relation[:sql]
    schema(:users, infer: true)
  end

  class UserTestRepo < Realm::Persistence::ROM::Repository[:users]
    auto_struct false
    commands :create

    def all
      users.to_a
    end

    def one(**conditions)
      users.where(**conditions.slice(:name)).one!
    end
  end
end

RSpec.describe Realm::Persistence::RepositoryQueryHandlerAdapter do
  let(:rom) do
    ROM.container(:sql, 'sqlite::memory') do |conf|
      conf.default.create_table(:users) do
        column :name, String, null: false
      end
      conf.register_relation(RepositoryQueryHandlerAdapterSpec::Users)
    end
  end
  let(:user_repo) { RepositoryQueryHandlerAdapterSpec::UserTestRepo.new(rom) }
  subject { described_class.new(user_repo) }

  before do
    rom.relations[:users].insert(name: 'Joe')
  end

  describe '.call' do
    it 'handles the queries' do
      expect(subject.(action: :all)).to eq([{ name: 'Joe' }])
      expect(subject.(action: :one, params: { name: 'Joe' })).to eq(name: 'Joe')
    end

    it 'forbids the writes' do
      expect {
        subject.(action: :create, params: { name: 'Amanda' })
      }.to raise_error(Realm::Persistence::QueryCannotModifyState)
    end

    it 'raise error when action is not available' do
      expect { subject.(action: :foo) }.to raise_error(Realm::CannotHandleAction)
    end
  end
end
