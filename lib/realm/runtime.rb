# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'realm/context'
require 'realm/container'
require 'realm/dispatcher'
require 'realm/event_router'
require 'realm/multi_worker'
require 'realm/health_status'
require 'realm/runtime/session'

module Realm
  class Runtime
    delegate :query, :run, :run_as_job, :wait_for_jobs, to: :dispatcher
    delegate :trigger, :add_listener, to: :event_router
    delegate :[], to: :context
    attr_reader :container

    def initialize(container = Container.new)
      @container = Container[container]
    end

    def context
      @context ||= Context.new(@container)
    end

    def session(context = {})
      context.blank? ? self : Session.new(self, context)
    end

    def worker(*args)
      MultiWorker.new(event_router.try(:workers, *args) || [])
    end

    def health
      component_statuses = context.each_with_object({}) do |(name, component), map|
        map[name] = component.health if component.respond_to?(:health)
      end
      HealthStatus.combine(component_statuses)
    end

    # Get all active messaging queues. For maintenance purpose only.
    # TODO: Introduce component container and allow to call those method directly on components instead of
    # polluting runtime
    # Example: engine.realm.components.find(type: Realm::EventRouter::SNSGateway).try(:active_queues)
    def active_queues
      event_router.try(:active_queues) || []
    end

    private

    def dispatcher
      @dispatcher ||= container.create(Dispatcher, self)
    end

    def event_router
      @container[EventRouter]
    end
  end
end
