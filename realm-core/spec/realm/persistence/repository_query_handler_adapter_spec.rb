# frozen_string_literal: true

require 'realm/persistence/repository_query_handler_adapter'

RSpec.describe Realm::Persistence::RepositoryQueryHandlerAdapter do
  context 'when repository supports has readonly method' do
    let(:readonly_repo) { double(:readonly_repo, fake_query: :query_return, class: :readonly_repo_class) }
    let(:repo) { double(:repo, readonly: readonly_repo) }
    subject { described_class.new(repo) }

    describe '.call' do
      it 'passes on the actions and params to repository' do
        expect(readonly_repo).to receive(:find_user).with(name: 'Joe').and_return(:joe)
        expect(subject.(action: :find_user, params: { name: 'Joe' })).to eq(:joe)
      end

      it 'wraps RepositoryIsReadOnly exception' do
        expect(readonly_repo).to receive(:change) { raise Realm::Persistence::RepositoryIsReadOnly, readonly_repo }
        expect { subject.(action: :change) }.to raise_error(Realm::Persistence::QueryCannotModifyState)
      end

      it 'raise error when action is not available' do
        expect { subject.(action: :foo) }.to raise_error(Realm::CannotHandleAction)
      end
    end
  end
end
