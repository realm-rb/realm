# frozen_string_literal: true

module Realm
  module InternalEventLoop
    class Plugin < Realm::Plugin
      inject EventRouter

      def setup
        event_router.register_gateway(gateway)
      end

      private

      def gateway
        container.create(
          InternalEventLoop::Gateway,
          queue_prefix: config[:prefix],
          event_factory: EventFactory.new(plugin_config.fetch(:events_module)),
          **plugin_config.except(:events_module),
        )
      end
    end
  end
end
