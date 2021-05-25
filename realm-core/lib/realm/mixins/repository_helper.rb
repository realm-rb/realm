# frozen_string_literal: true

module Realm
  module Mixins
    module RepositoryHelper
      class OnlyOneWriteRepo < Realm::Error['You can have only one read/write repo per handler']; end
      class InjectingRepoOutsideAggregate < Realm::Error['Cannot auto inject repository outside of an aggregate']; end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        protected

        def use_repo(*names, readonly: self < Realm::QueryHandler)
          raise OnlyOneWriteRepo if !readonly && (names.size > 1 || defined?(@write_repo_injected))

          names << default_repo_name if names.empty?
          names.each { |name| inject_repo(name, readonly) }
          @write_repo_injected = true unless readonly
        end

        private

        def inject_repo(name, readonly)
          repo_name = "#{name}_repo"
          return inject(repo_name) unless readonly

          inject(repo_name) { |repo| repo.respond_to?(:readonly) ? repo.readonly : repo }
        end

        def default_repo_name
          raise InjectingRepoOutsideAggregate unless respond_to?(:aggregate)

          aggregate
        end
      end
    end
  end
end
