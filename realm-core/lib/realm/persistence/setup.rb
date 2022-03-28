# frozen_string_literal: true

module Realm
  module Persistence
    class Setup
      def initialize(config, plugin_config, gateway_class)
        @config = config
        @plugin_config = plugin_config
        @gateway_class = gateway_class
      end

      def gateway
        @gateway ||= @gateway_class.new(**gateway_config)
      end

      def register_repos(container)
        repositories = @plugin_config[:repositories] || scan_repositories
        repositories.each do |repo_class|
          container.register_factory(repo_class, gateway, as: "#{repo_class.name.demodulize.underscore}_repo")
        end
      end

      private

      def gateway_config
        @gateway_config ||= GatewayConfigFactory.generate(@config, @plugin_config)
      end

      def scan_repositories
        return [] unless gateway_config[:repos_path]

        Dir[File.join(gateway_config[:repos_path], '**', '*.rb')].each_with_object([]) do |filename, all|
          matches = %r{^#{gateway_config[:repos_path]}/(.+)\.rb$}.match(filename)
          all << "#{gateway_config[:repos_module]}::#{matches[1].camelize}".constantize if matches
        end
      end
    end
  end
end
