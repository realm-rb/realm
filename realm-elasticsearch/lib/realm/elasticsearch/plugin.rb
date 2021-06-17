# frozen_string_literal: true

require 'realm/plugin'
require_relative 'gateway'

module Realm
  module Elasticsearch
    class Plugin < Realm::Plugin
      def self.setup(config, container)
        return unless config.persistence_gateway[:type] == :elasticsearch

        container.register_factory(Gateway, config.persistence_gateway, as: 'persistence.gateway')
      end
    end
  end
end
