# frozen_string_literal: true

module Realm
  module Persistence
    class GatewayConfigFactory
      def self.generate(...)
        new(...).generate
      end

      def initialize(config, plugin_config)
        @cfg = config
        @plugin_config = plugin_config
      end

      def generate
        return @plugin_config unless @cfg.app_root

        {
          class_namespace: @cfg.namespaced_classes ? @cfg.root_module : nil,
          schema: @cfg.engine_class ? @cfg.namespace : nil,
          class_path: class_path,
          repos_path: repos_path,
          repos_module: repos_module,
          migration_path: File.join(@cfg.root_path, 'db', 'migrate'),
        }.merge(@plugin_config)
      end

      private

      def class_path
        @class_path ||= begin
          parts = [@cfg.app_root, 'persistence', @cfg.namespaced_classes ? @cfg.namespace : nil].compact
          File.join(parts)
        end
      end

      def repos_path
        @repos_path ||= File.join(class_path, 'repositories')
      end

      def repos_module
        @repos_module ||= @cfg.namespaced_classes ? "#{@cfg.root_module}::Repositories" : 'Repositories'
      end
    end
  end
end
