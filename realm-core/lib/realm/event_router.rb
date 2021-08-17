# frozen_string_literal: true

module Realm
  class EventRouter
    include Mixins::DependencyInjection
    inject DomainResolver
    inject 'Realm::Runtime', lazy: true

    def initialize(prefix: nil)
      @prefix = prefix
      @gateways = {}
      @handler_registered_namespaces = []
    end

    def register(handler_class)
      gateway_for(handler_class.namespace).register(handler_class)
    end

    def register_gateway(gateway)
      raise "Multiple gateways for #{gateway.namespace || 'default'} namespace" if @gateways.key?(gateway.namespace)

      @gateways[gateway.namespace] = gateway
      register_handlers(gateway.namespace) if gateway.register_handlers_on_init
    end

    def add_listener(event_type, listener, namespace: nil)
      gateway_for(namespace).add_listener(event_type, listener)
    end

    def trigger(identifier, attributes = {})
      namespace, event_type = identifier.to_s.include?('/') ? identifier.split('/') : [nil, identifier]
      gateway_for(namespace).trigger(event_type, attributes)
    end

    def workers(*namespaces, **options)
      register_handlers
      @gateways.filter_map do |(namespace, gateway)|
        gateway.worker(**options) if namespaces.empty? || namespaces.include?(namespace)
      end
    end

    def active_queues
      register_handlers
      @gateways.values.reduce([]) do |queues, gateway|
        queues + gateway.queues
      end
    end

    private

    def register_handlers(*namespaces)
      return unless domain_resolver

      (namespaces.presence || @gateways.keys).each do |namespace|
        next if @handler_registered_namespaces.include?(namespace)

        @handler_registered_namespaces << namespace
        domain_resolver.all_event_handlers.each do |handler|
          register(handler) if handler.namespace == namespace
        end
      end
    end

    def gateway_for(namespace, fail: true)
      @gateways.fetch(namespace ? namespace.to_sym : :default) do
        raise "No event gateway for #{namespace || 'default'} namespace" if fail
      end
    end
  end
end
