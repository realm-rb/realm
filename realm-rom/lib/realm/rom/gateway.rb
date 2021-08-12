# frozen_string_literal: true

require 'dry-initializer'

module Realm
  module ROM
    class Gateway
      extend Dry::Initializer

      with_options reader: false do
        option :url
        option :class_path
        option :migration_path
        option :class_namespace, default: proc {}
        option :db_namespace, default: proc {}
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
