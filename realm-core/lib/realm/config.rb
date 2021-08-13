# frozen_string_literal: true

require 'dry-initializer'

module Realm
  class Config
    extend Dry::Initializer

    option :root_module
    option :prefix,               default: proc {}
    option :namespace,            default: proc { root_module.to_s.underscore }
    option :namespaced_classes,   default: proc { app_class.nil? }
    option :app_class,            default: proc { "#{root_module}::Application".safe_constantize }
    option :engine_class,         default: proc { "#{root_module}::Engine".safe_constantize }
    option :domain_module,        default: proc { namespaced('Domain').safe_constantize }
    option :root_path,            default: proc { (app_class || engine_class)&.root }
    option :app_root,             default: proc { root_path && File.join(root_path, 'app') }
    option :logger,               default: proc {}
    option :plugins,              default: proc { [] }
    option :dependencies,         default: proc { {} }
    option :event_gateway,        default: proc {}, reader: false
    option :event_gateways,       default: proc {
      @event_gateway ? { default: { **@event_gateway, default: true } } : {}
    }

    def plugins
      Array(@plugins)
    end

    private

    def namespaced(class_name)
      namespaced_classes ? "#{root_module}::#{class_name}" : class_name
    end
  end
end
