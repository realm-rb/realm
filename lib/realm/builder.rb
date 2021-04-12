# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'active_support/core_ext/object/with_options'
require 'dry-initializer'
require 'realm/container'
require 'realm/context'
require 'realm/runtime'
require 'realm/domain_resolver'
require 'realm/persistence'

module Realm
  class Builder
    extend Dry::Initializer

    attr_reader :runtime

    with_options reader: false do
      param :root_module
      option :database_url,         default: proc { nil }
      option :prefix,               default: proc { nil }
      option :namespace,            default: proc { @root_module.to_s.underscore }
      option :domain_module,        default: proc { "#{@root_module}::Domain" }
      option :engine_class,         default: proc { "#{@root_module}::Engine" }
      option :engine_path,          default: proc { constantize(@engine_class)&.root }
      option :domain_resolver,      default: proc { constantize(@domain_module)&.then { |m| DomainResolver.new(m) } }
      option :logger,               default: proc { nil }
      option :dependencies,         default: proc { {} }
      option :job_scheduler,        default: proc { {} }
      option :persistence_gateway,  default: proc { @database_url && { url: @database_url } }
      # TODO: support multiple persistence gateways
      option :event_gateway,        default: proc { nil }
      option :event_gateways,       default: proc {
        @event_gateway ? { default: { **@event_gateway, default: true } } : {}
      }
    end

    def self.setup(root_module, **options)
      new(root_module, **options).setup
    end

    def setup
      @container = Container.new
      @context = nil
      @runtime = nil
      config_persistence
      @container.register_all(logger: @logger, **@dependencies)
      create_runtime
      self
    end

    private

    def context
      @context ||= Context.new(@container)
    end

    def config_persistence
      return unless @persistence_gateway.present?

      options = persistence_defaults.merge(@persistence_gateway)
      Persistence.setup(@root_module, options)
    end

    def create_runtime
      @runtime = Runtime.new(
        context: context,
        domain_resolver: @domain_resolver,
        event_gateways_config: @event_gateways,
        prefix: @prefix,
      )
    end

    def constantize(*parts)
      return parts[0] unless parts[0].is_a?(String)

      parts.join('::').safe_constantize
    end

    def persistence_defaults
      class_path = @engine_path && "#{@engine_path}/app/persistence/#{@namespace}"
      {
        type: :rom,
        container: @container,
        class_path: class_path,
        repos_path: class_path && "#{class_path}/repositories",
        repos_module: "#{@root_module}::Repositories",
        migration_path: @engine_path && "#{@engine_path}/db/migrate",
      }
    end

    def logger
      return @logger if @logger

      return Rails.logger if defined?(Rails)

      @logger = Logger.new($stdout, level: ENV.fetch('LOG_LEVEL', :info).to_sym)
    end
  end
end
