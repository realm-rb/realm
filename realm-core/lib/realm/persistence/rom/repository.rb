# frozen_string_literal: true

require 'rom-repository'
require_relative 'read_only_repository_wrapper'

module Realm
  class Persistence
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
          end

          def respond_to_missing?(*args)
            @repo.respond_to?(*args)
          end
        end

        def self.new(*)
          Isolated.new(super)
        end

        def readonly
          @readonly ||= Realm::Persistence::ROM::ReadOnlyRepositoryWrapper.new(self)
        end
      end
    end
  end
end