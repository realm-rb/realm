# frozen_string_literal: true

module Realm
  class Runtime
    class Session
      delegate :query, :run, :run_as_job, :wait_for_jobs, to: :@dispatcher
      delegate :add_listener, :trigger, :worker, to: :@runtime
      delegate :[], to: :context
      attr_reader :context

      def initialize(runtime, dispatcher, context)
        @runtime = runtime
        @context = runtime.context.merge(context)
        @dispatcher = dispatcher.fork(self)
      end

      def session(context = {})
        context.blank? ? self : self.class.new(self, @dispatcher, context)
      end
    end
  end
end
