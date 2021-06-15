# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_support/core_ext/object/with_options'
require 'dry-initializer'
require 'realm/error'

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

    extend Dry::Initializer

    with_options reader: false do
      param :root_module
      param :container
      option :type
      option :url
      option :class_path
      option :migration_path
      option :repositories
    end

    class << self
      def setup(...)
        new(...).setup
      end
    end

    def setup
      register_repos
    end

    private

    def gateway
      @gateway ||= @type == :rom ? rom_gateway : @container.resolve('persistence.gateway')
    end

    # Temporary solution until rom plugin is extracted from core
    def rom_gateway
      return @container[@type] if @container.key?(@type)

      gateway = ROM::Gateway.configure(
        url: @url,
        root_module: @root_module,
        class_path: @class_path,
        migration_path: @migration_path,
      )
      @container.register(@type, gateway)
      gateway
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
