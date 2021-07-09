# frozen_string_literal: true

module Realm
  class Persistence
    class InvalidPersistanceType < Realm::Error; end
    class Conflict < Realm::Error; end

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

    def self.setup(...)
      new(...).setup
    end

    def initialize(container, repositories)
      @container = container
      @repositories = repositories
    end

    def setup
      register_repos
    end

    private

    def gateway
      @gateway ||= @container.resolve('persistence.gateway')
    end

    def register_repos
      @repositories.each do |repo_class|
        @container.register_factory(repo_class, gateway, as: "#{repo_class.name.demodulize.underscore}_repo")
      end
    end

    def constantize(*parts)
      return parts[0] unless parts[0].is_a?(String)

      parts.join('::').safe_constantize
    end
  end
end
