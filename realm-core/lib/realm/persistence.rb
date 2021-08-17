# frozen_string_literal: true

module Realm
  module Persistence
    class InvalidPersistanceType < Realm::Error; end
    class Conflict < Realm::Error; end
    class QueryCannotModifyState < Realm::Error; end

    class RelationIsReadOnly < Realm::Error
      def initialize(relation, msg: "Cannot write using read-only relation #{relation.class}")
        super(msg)
      end
    end

    class RepositoryIsReadOnly < Realm::Error
      def initialize(repo, msg: "Cannot write using read-only repository #{repo.class}")
        super(msg)
      end
    end
  end
end
