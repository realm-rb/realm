# frozen_string_literal: true

require 'typhoeus'
require 'elasticsearch'
require 'realm/health_status'
require_relative 'repository'

module Realm
  module Elasticsearch
    class Gateway
      def initialize(url:, **options)
        @url = url
        @client_options = options.slice(:adapter, :retry_on_failure, :request_timeout)
      end

      def health
        issues = []
        index_names = Repository.subclasses.map(&:index_name)
        begin
          issues << 'One or more indexes missing' unless @client.indices.exists(index: index_names)
        rescue StandardError => e
          issues << "Elasticsearch connection error: #{e.full_message}"
        end
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
        @client ||= ::Elasticsearch::Client.new(default_config.merge(@client_options))
      end

      def default_config
        {
          url: @url,
          adapter: :typhoeus,
          retry_on_failure: 3,
          request_timeout: 30,
        }
      end
    end
  end
end
