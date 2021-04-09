# frozen_string_literal: true

require 'yaml'

module Realm
  class Persistence
    module Elasticsearch
      module RakeTasks
        class << self
          def setup(engine_name, engine_root: nil, url: ENV['ELASTICSEARCH_URL'])
            return unless url

            client = ::Elasticsearch::Client.new(url: url)

            Rake.application.in_namespace(:es) do
              Rake::Task.define_task(:create_indexes) do
                with_definitions(engine_name, engine_root) do |index, config|
                  client.indices.create(index: index, body: config) unless client.indices.exists(index: index)
                end
              end

              Rake::Task.define_task(:drop_indexes) do
                with_definitions(engine_name, engine_root) do |index, _config|
                  client.indices.delete(index: index) if client.indices.exists(index: index)
                end
              end
            end
          end

          private

          def with_definitions(engine_name, engine_root)
            engine_root ||= Rails.root.join('engines', engine_name.to_s)
            Dir.glob(File.join(engine_root, 'elasticsearch/indexes/*.yaml')).each do |path|
              yield File.basename(path, '.yaml'), YAML.safe_load(File.read(path))
            end
          end
        end
      end
    end
  end
end
