# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string'
require 'realm/action_handler'
require 'realm/mixins/reactive'

module Realm
  class CommandHandler < Realm::ActionHandler
    include Mixins::Reactive

    def call(*)
      gateway = context[:rom]&.gateways&.dig(:default)
      gateway ? gateway.transaction { super } : super
    end

    protected

    def result(first, second = nil)
      Result[first, second]
    end
  end
end
