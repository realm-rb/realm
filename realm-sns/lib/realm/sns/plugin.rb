# frozen_string_literal: true

require 'realm/plugin'
require_relative 'gateway'

module Realm
  module SNS
    class Plugin < Realm::Plugin
      name :sns

      def self.setup(_config, container)
        container.register('event_router.gateway_classes.sns', SNS::Gateway)
      end
    end
  end
end
