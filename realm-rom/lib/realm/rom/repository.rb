# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'rom-repository'
require 'realm/error'
require_relative 'read_only_repository_wrapper'

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
        rescue ROM::SQL::UniqueConstraintError
          raise Realm::UniqueConstraintError
        end

        def respond_to_missing?(*args)
          @repo.respond_to?(*args)
        end
      end

      def self.new(*)
        Isolated.new(super)
      end

      def self.repo_name(value = :not_provided)
        @repo_name = value.to_sym unless value == :not_provided
        @repo_name = name.demodulize.underscore unless defined?(@repo_name)
        @repo_name
      end

      def readonly
        @readonly ||= ROM::ReadOnlyRepositoryWrapper.new(self)
      end
    end
  end
end