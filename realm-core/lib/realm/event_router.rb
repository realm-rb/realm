# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'realm/error'
require 'realm/domain_resolver'
require 'realm/event_handler'
require 'realm/event_factory'
require 'realm/mixins/dependency_injection'
require_relative 'event_router/internal_loop_gateway'

module Realm
  class EventRouter
    include Mixins::DependencyInjection
    inject DomainResolver
    inject 'Realm::Runtime', lazy: true

    def initialize(gateways_spec, prefix: nil)
      @prefix = prefix
      @auto_registered = false
      @default_namespace = nil
      init_gateways(gateways_spec)
    end

    def register(handler_class)
      gateway_for(handler_class.try(:event_namespace)).register(handler_class)
    end

    def add_listener(event_type, listener, namespace: nil)
      gateway_for(namespace).add_listener(event_type, listener)
    end

    def trigger(identifier, attributes = {})
      namespace, event_type = identifier.to_s.include?('.') ? identifier.split('.') : [nil, identifier]
      gateway_for(namespace).trigger(event_type, attributes)
    end

    def workers(*namespaces, **options)
      auto_register_handlers
      @gateways.filter_map do |(namespace, gateway)|
        gateway.worker(**options) if namespaces.empty? || namespaces.include?(namespace)
      end
    end

    def active_queues
      auto_register_handlers
      @gateways.values.reduce([]) do |queues, gateway|
        queues + gateway.queues
      end
    end

    private

    def init_gateways(gateways_spec)
      auto_register_on_init = false
      @gateways = gateways_spec.each_with_object({}) do |(namespace, config), gateways|
        gateway_class = gateway_class(config.fetch(:type))
        auto_register_on_init ||= gateway_class.auto_register_on_init
        gateways[namespace] = instantiate_gateway(namespace, gateway_class, config)
        @default_namespace = namespace if config[:default]
      end
      auto_register_handlers if auto_register_on_init
    end

    def gateway_class(type)
      return InternalLoopGateway if type.to_s == 'internal_loop'

      runtime.container.resolve("event_router.gateway_classes.#{type}")
    end

    def instantiate_gateway(namespace, klass, config)
      klass.new(
        namespace: namespace,
        queue_prefix: @prefix,
        event_factory: EventFactory.new(config.fetch(:events_module)),
        runtime: runtime,
        **config.except(:type, :default, :events_module),
      )
    end

    def auto_register_handlers
      return if @auto_registered || !domain_resolver

      @auto_registered = true
      domain_resolver.all_event_handlers.each { |klass| register(klass) }
    end

    def gateway_for(namespace)
      @gateways.fetch(namespace.try(:to_sym) || default_namespace) do
        raise "No event gateway for #{namespace || 'default'} namespace" # TODO: extract error class
      end
    end

    def default_namespace
      return @default_namespace if @default_namespace

      @gateways.keys[0] if @gateways.keys.size == 1
    end
  end
end
