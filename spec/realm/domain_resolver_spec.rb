# frozen_string_literal: true

require 'spec_helper'
require 'realm/domain_resolver'
require 'realm/command_handler'
require 'realm/query_handler'
require 'realm/event_handler'

module DomainResolverSpec
  module Post
    class Create < Realm::CommandHandler; end
    class UpdateHandler < Realm::CommandHandler; end
    class DeleteCommandHandler < Realm::CommandHandler; end

    module CommandHandlers
      class Another < Realm::CommandHandler; end
    end

    class Find < Realm::QueryHandler; end
    class ListAllHandler < Realm::QueryHandler; end
    class ListRecentQueryHandler < Realm::QueryHandler; end

    class QueryHandlers < Realm::QueryHandler; end

    class EventHandler < Realm::EventHandler; end
  end
end

RSpec.describe Realm::DomainResolver do
  subject { described_class.new(DomainResolverSpec) }

  describe '#get_handler_with_action' do
    it 'looks up the handler class and action using consistent naming conventions' do
      {
        [Realm::CommandHandler, 'post.create'] => [DomainResolverSpec::Post::Create, :handle],
        [Realm::CommandHandler, 'post.update'] => [DomainResolverSpec::Post::UpdateHandler, :handle],
        [Realm::CommandHandler, 'post.delete'] => [DomainResolverSpec::Post::DeleteCommandHandler, :handle],
        [Realm::CommandHandler, 'post.another'] => [DomainResolverSpec::Post::CommandHandlers::Another, :handle],
        [Realm::QueryHandler, 'post.find'] => [DomainResolverSpec::Post::Find, :handle],
        [Realm::QueryHandler, 'post.list_all'] => [DomainResolverSpec::Post::ListAllHandler, :handle],
        [Realm::QueryHandler, 'post.list_recent'] => [DomainResolverSpec::Post::ListRecentQueryHandler, :handle],
        [Realm::QueryHandler, 'post.another'] => [DomainResolverSpec::Post::QueryHandlers, :another],
      }.each_pair do |args, result|
        expect(subject.get_handler_with_action(*args)).to eq(result)
      end
    end
  end

  describe '#all_event_handlers' do
    it 'returns all event handler classes' do
      expect(subject.all_event_handlers).to eq([DomainResolverSpec::Post::EventHandler])
    end
  end
end
