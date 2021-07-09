# frozen_string_literal: true

module Realm
  module SNS
    class Plugin < Realm::Plugin
      def self.setup(_config, container)
        container.register('event_router.gateway_classes.sns', SNS::Gateway)
      end
    end
  end
end
