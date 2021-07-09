# frozen_string_literal: true

module Realm
  class Persistence
    class QueryCannotModifyState < Realm::Error; end

    class RepositoryQueryHandlerAdapter
      def initialize(repo)
        @repo = repo.respond_to?(:readonly) ? repo.readonly : repo
      end

      def call(action:, params: {}, **)
        raise CannotHandleAction.new(self, action) unless @repo.respond_to?(action)

        @repo.send(action, **params)
      rescue RepositoryIsReadOnly
        raise QueryCannotModifyState
      end
    end
  end
end
