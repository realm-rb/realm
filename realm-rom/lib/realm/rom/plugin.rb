# frozen_string_literal: true

require 'realm/plugin'
require_relative 'gateway'

module Realm
  module ROM
    class Plugin < Realm::Plugin
      def self.setup(config, container)
        return unless config.persistence_gateway[:type] == :rom

        gateway = Gateway.configure(config.persistence_gateway)
        container.register('persistence.gateway', gateway)
        container.register(:rom, gateway) # for backward compatibility as we access it a lot in tests
      end
    end
  end
end
