# frozen_string_literal: true

require 'dry-initializer'

module Realm
  class Config
    extend Dry::Initializer

    option :root_module
    option :database_url,         default: proc {}
    option :prefix,               default: proc {}
    option :namespace,            default: proc { root_module.to_s.underscore }
    option :domain_module,        default: proc { "#{root_module}::Domain" }
    option :engine_class,         default: proc { "#{root_module}::Engine" }
    option :engine_path,          default: proc { engine_class&.to_s&.safe_constantize&.root }
    option :logger,               default: proc {}
    option :plugins,              default: proc { [] }, reader: false
    option :dependencies,         default: proc { {} }
    option :persistence_gateway,  default: proc { database_url && { type: :rom, url: database_url } }, reader: false
    option :event_gateway,        default: proc {}, reader: false
    option :event_gateways,       default: proc {
      @event_gateway ? { default: { **@event_gateway, default: true } } : {}
    }

    def plugins
      Array(@plugins)
    end

    def persistence_gateway
      return {} unless @persistence_gateway

      class_path = engine_path && "#{engine_path}/app/persistence/#{namespace}"
      repos_path = class_path && "#{class_path}/repositories"
      repos_module = "#{root_module}::Repositories"
      {
        root_module: root_module,
        class_path: class_path,
        repos_path: repos_path,
        repos_module: repos_module,
        migration_path: engine_path && "#{engine_path}/db/migrate",
        repositories: repositories(repos_path, repos_module),
      }.merge(@persistence_gateway)
    end

    private

    def repositories(repos_path, repos_module)
      return [] unless repos_path

      Dir[File.join(repos_path, '**', '*.rb')].each_with_object([]) do |filename, all|
        matches = %r{^#{repos_path}/(.+)\.rb$}.match(filename)
        all << "#{repos_module}::#{matches[1].camelize}".constantize if matches
      end
    end
  end
end
