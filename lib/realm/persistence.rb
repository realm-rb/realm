# frozen_string_literal: true

require 'active_support/core_ext/object/with_options'

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
      option :container
      option :type
      option :url
      option :repos_module
      option :class_path
      option :migration_path
      option :repos_path
    end

    class << self
      def setup(root_module, **options)
        new(root_module, **options).setup
      end
    end

    def setup
      client = client_klass.configure(
        url: @url,
        root_module: @root_module,
        class_path: @class_path,
        migration_path: @migration_path,
      )
      # FIXME: check how to deal with the forking
      @container.register(@type, client)
      register_repos(client)
    end

    private

    def register_repos(client)
      return unless @repos_path.present?

      Dir[File.join(@repos_path, '**', '*.rb')].each do |filename|
        matches = %r{^#{@repos_path}/(.+)\.rb$}.match(filename)
        next unless matches

        @container.register("#{matches[1]}_repo", constantize(@repos_module, matches[1].camelize).new(client))
      end
    end

    def constantize(*parts)
      return parts[0] unless parts[0].is_a?(String)

      parts.join('::').safe_constantize
    end

    def client_klass
      @client_klass ||= client_for_type(@type)
    end

    def client_for_type(_type)
      return ROM::Gateway if @type == :rom
      return Elasticsearch::Gateway if @type == :elasticsearch

      raise InvalidPersistanceType
    end
  end
end
