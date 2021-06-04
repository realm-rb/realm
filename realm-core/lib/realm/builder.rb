# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'realm/container'
require 'realm/runtime'
require 'realm/domain_resolver'
require 'realm/persistence'
require 'realm/dispatcher'
require 'realm/event_router'
require 'realm/plugin'

module Realm
  class Builder
    extend Dry::Initializer

    def self.setup(config)
      new(config).setup
    end

    def initialize(config)
      @config = config
    end

    def setup
      logger.info("Setting up #{cfg.root_module} realm")
      register_domain_resolver
      register_event_router
      register_runtime
      register_logger
      register_dependencies
      setup_plugins
      config_persistence
      self
    end

    def runtime
      @container.resolve(Runtime)
    end

    private

    def register_domain_resolver
      container.register_factory(DomainResolver, constantize(cfg.domain_module))
    end

    def register_event_router
      return if cfg.event_gateways.empty?

      container.register_factory(EventRouter, cfg.event_gateways, prefix: cfg.prefix)
    end

    def register_runtime
      container.register_factory(Runtime, container)
    end

    def register_logger
      container.register(:logger, logger)
    end

    def register_dependencies
      container.register_all(**cfg.dependencies)
    end

    def setup_plugins
      Plugin.descendants.each do |plugin|
        plugin.setup(cfg, container) if cfg.plugins.include?(plugin.name)
      end
    end

    def config_persistence
      return unless cfg.persistence_gateway.present?

      options = persistence_defaults.merge(cfg.persistence_gateway)
      Persistence.setup(cfg.root_module, options)
    end

    def constantize(*parts)
      return parts[0] unless parts[0].is_a?(String)

      parts.join('::').safe_constantize
    end

    def persistence_defaults
      class_path = cfg.engine_path && "#{cfg.engine_path}/app/persistence/#{cfg.namespace}"
      {
        type: :rom,
        container: @container,
        class_path: class_path,
        repos_path: class_path && "#{class_path}/repositories",
        repos_module: "#{cfg.root_module}::Repositories",
        migration_path: cfg.engine_path && "#{cfg.engine_path}/db/migrate",
      }
    end

    def cfg
      @config
    end

    def container
      @container ||= Container.new
    end

    def logger
      @logger ||= cfg.logger || (defined?(Rails) && Rails.logger) ||
                  Logger.new($stdout, level: ENV.fetch('LOG_LEVEL', :info).to_sym)
    end
  end
end
