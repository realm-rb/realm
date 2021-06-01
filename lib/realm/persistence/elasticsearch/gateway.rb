# frozen_string_literal: true

require 'typhoeus'
require 'elasticsearch'
require 'realm/health_status'
require 'realm/persistence/gateway'
require_relative 'repository'

module Realm
  class Persistence
    module Elasticsearch
      class Gateway < Persistence::Gateway
        def initialize(url:, **) # rubocop:disable Lint/MissingSuper
          @url = url
        end

        def configure
          @client = ::Elasticsearch::Client.new(
            url: @url,
            adapter: :typhoeus,
            retry_on_failure: 3,
            request_timeout: 30,
          )
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
      end
    end
  end
end
