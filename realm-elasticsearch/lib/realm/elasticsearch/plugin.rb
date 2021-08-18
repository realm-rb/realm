# frozen_string_literal: true

module Realm
  module Elasticsearch
    class Plugin < Realm::Plugin
      def setup
        # TODO: add namespace to support for multiple persistence gateways
        container.register('persistence.gateway', persistence_setup.gateway)
        persistence_setup.register_repos(container)
      end

      private

      def persistence_setup
        @persistence_setup ||= Persistence::Setup.new(config, plugin_config, Gateway)
      end
    end
  end
end
