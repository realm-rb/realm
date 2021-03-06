# frozen_string_literal: true

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
      attr_reader :trigger_mapping

      def bind_runtime(runtime)
        RuntimeBound.new(self, runtime)
      end

      def call(event, runtime:)
        new(runtime: runtime).(event)
      end

      def identifier(value = :not_provided)
        @identifier = value unless value == :not_provided
        return @identifier if defined?(@identifier)

        @identifier = name.gsub(/(Domain|(::)?(Event)?Handlers?)/, '').underscore.gsub(%r{/+}, '-')
      end

      def event_types
        defined?(@trigger_mapping) ? @trigger_mapping.keys.uniq : []
      end

      def namespace(value = :not_provided)
        @namespace = value.to_sym unless value == :not_provided
        @namespace ||= :default
      end

      protected

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
      rescue Realm::Persistence::Conflict => e
        context[:logger]&.warn(e.full_message)
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
