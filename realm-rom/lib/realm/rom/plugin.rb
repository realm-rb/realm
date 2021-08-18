# frozen_string_literal: true

module Realm
  module ROM
    class Plugin < Realm::Plugin
      def setup
        # TODO: add namespace to support for multiple persistence gateways
        @gateway = Gateway.new(gateway_config)
        container.register('persistence.gateway', @gateway)
        container.register(:rom, @gateway) # for backward compatibility as we access it a lot in tests
        register_repos
      end

      private

      def gateway_config
        @gateway_config ||= Persistence::GatewayConfigFactory.generate(config, plugin_config)
      end

      def register_repos
        repositories = plugin_config[:repositories] || scan_repositories
        repositories.each do |repo_class|
          container.register_factory(repo_class, @gateway, as: "#{repo_class.name.demodulize.underscore}_repo")
        end
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
