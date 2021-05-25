# frozen_string_literal: true

require 'realm/dispatcher'

module Realm
  class Runtime
    class Session
      delegate :query, :run, :run_as_job, :wait_for_jobs, to: :dispatcher
      delegate :add_listener, :trigger, :worker, to: :@runtime
      delegate :[], to: :context
      attr_reader :context

      def initialize(runtime, context)
        @runtime = runtime
        @context = runtime.context.merge(context)
      end

      def session(context = {})
        context.blank? ? self : self.class.new(self, context)
      end

      def container
        @runtime.container
      end

      private

      def dispatcher
        @dispatcher ||= container.create(Dispatcher, self)
      end
    end
  end
end
