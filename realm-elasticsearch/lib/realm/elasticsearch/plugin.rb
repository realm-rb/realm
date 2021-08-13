# frozen_string_literal: true

module Realm
  module Elasticsearch
    class Plugin < Realm::Plugin
      def setup
        # TODO: add namespace to support for multiple persistence gateways
        @gateway = Gateway.new(plugin_config)
        container.register('persistence.gateway', @gateway)
        register_repos
      end

      private

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
