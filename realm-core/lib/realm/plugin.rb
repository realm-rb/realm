# frozen_string_literal: true

module Realm
  class Plugin
    include Mixins::DependencyInjection

    def self.plugin_name(value = :not_provided)
      @plugin_name = value.to_sym unless value == :not_provided
      @plugin_name ||= name.split('::')[-2].underscore.to_sym
    end

    def initialize(config, plugin_config, container)
      @config = config
      @plugin_config = plugin_config
      @container = container
    end

    def setup
      raise NotImplementedError
    end

    protected

    attr_reader :config, :plugin_config, :container
  end
end
