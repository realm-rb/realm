# frozen_string_literal: true

require 'dry-initializer'

module Realm
  class Config
    extend Dry::Initializer

    option :root_module
    option :database_url,         default: proc {}
    option :prefix,               default: proc {}
    option :namespace,            default: proc { root_module.to_s.underscore }
    option :namespaced_classes,   default: proc { app_class.nil? }
    option :app_class,            default: proc { "#{root_module}::Application".safe_constantize }
    option :engine_class,         default: proc { "#{root_module}::Engine".safe_constantize }
    option :domain_module,        default: proc { namespaced('Domain').safe_constantize }
    option :root_path,            default: proc { (app_class || engine_class)&.root }
    option :app_root,             default: proc { root_path && File.join(root_path, 'app') }
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

    # TODO: move this logic to realm-rom
    def persistence_gateway # rubocop:disable Metrics/AbcSize
      return {} unless @persistence_gateway && app_root

      class_path = File.join([app_root, 'persistence', namespaced_classes ? namespace : nil].compact)
      repos_path = File.join(class_path, 'repositories')
      repos_module = namespaced('Repositories')
      {
        class_namespace: namespaced_classes ? root_module : nil,
        db_namespace: engine_class ? namespace : nil,
        class_path: class_path,
        repos_path: repos_path,
        repos_module: repos_module,
        migration_path: File.join(root_path, 'db', 'migrate'),
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

    def namespaced(class_name)
      namespaced_classes ? "#{root_module}::#{class_name}" : class_name
    end
  end
end
