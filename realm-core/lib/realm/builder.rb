# frozen_string_literal: true

module Realm
  class Builder
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
      cfg.plugins.each do |plugin_config|
        klass = Plugin.descendants.find { |c| c.plugin_name == plugin_config[:name].to_sym }
        klass.setup(cfg, plugin_config, container)
      end
    end

    def constantize(*parts)
      return parts[0] unless parts[0].is_a?(String)

      parts.join('::').safe_constantize
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
