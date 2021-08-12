# frozen_string_literal: true

module Realm
  module ROM
    class Gateway
      def initialize(url:, class_path:, migration_path:, class_namespace: nil, db_namespace: nil, **)
        @url = url
        @class_path = class_path
        @migration_path = migration_path
        @class_namespace = class_namespace
        @db_namespace = db_namespace
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
          config.auto_registration(@class_path, namespace: @class_namespace&.to_s || false)
        end
      end

      def config_options
        { search_path: @db_namespace, migrator: { path: @migration_path } }
      end

      def default_gateway
        client.gateways[:default]
      end
    end
  end
end
