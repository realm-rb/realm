# frozen_string_literal: true

module Realm
  module ROM
    class ReadOnlyRepositoryWrapper
      def initialize(repo)
        @repo = repo.clone
        @repo.define_singleton_method(:root) { ReadOnlyRelationWrapper.new(super()) }
      end

      def method_missing(...)
        @repo.send(...)
      rescue Persistence::RelationIsReadOnly
        raise Persistence::RepositoryIsReadOnly, @repo
      end

      def respond_to_missing?(...)
        @repo.respond_to?(...)
      end
    end
  end
end
