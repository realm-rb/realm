# frozen_string_literal: true

require 'rom-repository'

module Realm
  module ROM
    class Repository < ::ROM::Repository::Root
      # Prevents leaking of persistence details into business logic
      class Isolated
        def initialize(repo)
          @repo = repo
        end

        def method_missing(*args, &block)
          result = @repo.send(*args, &block)
          result.is_a?(::ROM::Relation) ? result.to_a : result
        rescue ::ROM::SQL::UniqueConstraintError
          raise Realm::Persistence::Conflict
        end

        def respond_to_missing?(*args)
          @repo.respond_to?(*args)
        end
      end

      class << self
        def new(...)
          Isolated.new(super)
        end

        def repo_name(value = :not_provided)
          @repo_name = value.to_sym unless value == :not_provided
          @repo_name ||= name.demodulize.underscore
        end

        def queries(type)
          raise 'Only default queries are supported for now' unless type == :default

          include DefaultRepositoryQueries
        end
      end

      def readonly
        @readonly ||= ROM::ReadOnlyRepositoryWrapper.new(self)
      end
    end
  end
end
