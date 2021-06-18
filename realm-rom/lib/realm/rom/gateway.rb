# frozen_string_literal: true

require 'rom'
require 'realm/health_status'
require 'active_support/core_ext/string'

module Realm
  module ROM
    class Gateway
      def initialize(url:, root_module:, class_path:, migration_path:, **)
        @url = url
        @root_module = root_module
        @class_path = class_path
        @migration_path = migration_path
      end

      def health
        issues = []
        issues << 'Cannot connect to db' unless default_gateway.connection.test_connection
        issues << 'Pending migrations' if default_gateway.migrator.pending?
        HealthStatus.from_issues(issues)
      end

      def method_missing(...)
        client.send(...)
      end

      def respond_to_missing?(...)
        client.respond_to?(...)
      end

      private

      def client
        @client ||= ::ROM.container(config)
      end

      def config
        ::ROM::Configuration.new(:sql, @url, **config_options).tap do |config|
          config.auto_registration(@class_path, namespace: @root_module.to_s)
        end
      end

      def config_options
        { search_path: @root_module.to_s.underscore, migrator: { path: @migration_path } }
      end

      def default_gateway
        client.gateways[:default]
      end
    end
  end
end
