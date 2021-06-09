# frozen_string_literal: true

require 'realm/plugin'
require_relative 'gateway'

module Realm
  module Elasticsearch
    class Plugin < Realm::Plugin
      def self.setup(config, container)
        return unless config.persistence_gateway[:type] == :elasticsearch

        gateway = Gateway.configure(config.persistence_gateway)
        container.register('persistence.gateway', gateway)
      end
    end
  end
end
