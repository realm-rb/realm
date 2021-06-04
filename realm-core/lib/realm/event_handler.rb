# frozen_string_literal: true

require 'rom-sql'
require 'active_support/core_ext/string'
require 'realm/mixins/context_injection'
require 'realm/mixins/reactive'
require 'realm/mixins/repository_helper'
require 'realm/mixins/aggregate_member'

module Realm
  class EventHandler
    extend Mixins::ContextInjection::ClassMethods
    include Mixins::AggregateMember
    include Mixins::Reactive
    include Mixins::RepositoryHelper

    class RuntimeBound
      delegate :identifier, :event_types, to: :@handler_class

      def initialize(handler_class, runtime)
        @handler_class = handler_class
        @runtime = runtime
      end

      def call(event)
        @handler_class.(event, runtime: @runtime.session(cause: event))
      end
    end

    class << self
      attr_reader :trigger_mapping, :event_namespace

      def bind_runtime(runtime)
        RuntimeBound.new(self, runtime)
      end

      def call(event, runtime:)
        new(runtime: runtime).(event)
      end

      def identifier(value = :undefined)
        if value == :undefined
          defined?(@identifier) ? @identifier : name.gsub(/(Domain|EventHandlers?)/, '').underscore.gsub(%r{/+}, '-')
        else
          @identifier = value
        end
      end

      def event_types
        defined?(@trigger_mapping) ? @trigger_mapping.keys.uniq : []
      end

      protected

      def namespace(value)
        @event_namespace = value
      end

      def on(*triggers, run: nil, **options, &block)
        @method_triggers = triggers
        @method_trigger_options = options # TODO: store and pass to gateway
        return unless run || block

        block = ->(event) { self.run(run, event.body) } if run
        define_method("handle_#{triggers.join('_or_')}", &block)
      end

      def method_added(method_name)
        super
        return unless defined?(@method_triggers)

        @trigger_mapping ||= {}
        @method_triggers.each do |trigger|
          (@trigger_mapping[trigger.to_sym] ||= []) << method_name
        end
        remove_instance_variable(:@method_triggers)
      end
    end

    def initialize(runtime: nil)
      @runtime = runtime
    end

    def call(event)
      event_to_methods(event).each do |method_name|
        send(method_name, event)
      rescue ROM::SQL::UniqueConstraintError => e # TODO: wrap it in more generic error to avoid dependency on ROM
        # The unique constraints are way to deal with duplicated events which can happen in most distributed messaging
        # systems. Unless there are large amount of them we just ignore it and skip the event processing.
        context[:logger]&.warn(e)
      end
    end

    protected

    delegate :context, to: :@runtime

    private

    def event_to_methods(event)
      self.class.trigger_mapping.fetch_values(event.type.to_sym, :any) { [] }.flatten
    end
  end
end
