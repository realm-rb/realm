# frozen_string_literal: true

require 'active_support/core_ext/class'
require 'active_support/core_ext/string'

module Realm
  class Plugin
    class << self
      def plugin_name(value = :not_provided)
        @plugin_name = value.to_sym unless value == :not_provided
        @plugin_name = name.split('::')[-2].underscore.to_sym unless defined?(@plugin_name)
        @plugin_name
      end

      def setup(_config, _container)
        raise NotImplementedError
      end
    end
  end
end
