# frozen_string_literal: true

require 'rom'
require 'realm/health_status'
require 'realm/persistence/gateway'
require 'active_support/core_ext/string'

module Realm
  module ROM
    class Gateway < Persistence::Gateway
      def initialize(url:, root_module:, class_path:, migration_path:) # rubocop:disable Lint/MissingSuper
        @url = url
        @root_module = root_module
        @class_path = class_path
        @migration_path = migration_path
      end

      def configure
        config = ::ROM::Configuration.new(:sql, @url, **config_options)
        config.auto_registration(@class_path, namespace: @root_module.to_s)
        @client = ::ROM.container(config)
      end

      def health
        issues = []
        issues << 'Cannot connect to db' unless default_gateway.connection.test_connection
        issues << 'Pending migrations' if default_gateway.migrator.pending?
        HealthStatus.from_issues(issues)
      end

      private

      def config_options
        { search_path: @root_module.to_s.underscore, migrator: { path: @migration_path } }
      end

      def default_gateway
        @client.gateways[:default]
      end
    end
  end
end
