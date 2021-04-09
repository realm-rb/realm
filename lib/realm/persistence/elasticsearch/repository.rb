# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/string'

module Realm
  class Persistence
    module Elasticsearch
      class Repository
        def self.index_name
          @index_name ||= name.demodulize.underscore.pluralize
        end

        def initialize(client)
          @client = client
        end

        def find(id:)
          single(client.get(index: index_name, id: id))
        rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end

        def all
          multiple(raw_search(query: { match_all: {} }))
        end

        def create(id: nil, **attrs)
          client.index(index: index_name, type: '_doc', id: id, body: attrs, refresh: refresh?)
        rescue ::Elasticsearch::Transport::Transport::Errors::Conflict
          raise Realm::Persistence::Conflict
        end

        def update(id:, **attrs)
          raw_update(id, doc: attrs)
        end

        def upsert(id:, **attrs)
          raw_update(id, doc: attrs, doc_as_upsert: true)
        end

        def delete(id:)
          client.delete(index: index_name, type: '_doc', id: id, refresh: refresh?)
        rescue ::Elasticsearch::Transport::Transport::Errors::NotFound
          # ignore
        end

        def search_by(params)
          multiple(raw_search(query: { bool: { must: match_params(params) } }))
        end

        def delete_by(params)
          client.delete_by_query(
            index: index_name,
            body: { query: {
              bool: {
                must: match_params(params),
              },
            } },
          )
        end

        def raw_update(id, body = {})
          client.update(index: index_name, type: '_doc', id: id, body: body, refresh: refresh?)
        end

        def raw_search(yaml: nil, options: {}, **body)
          client.search(index: index_name, body: yaml ? YAML.safe_load(yaml) : body, **options)
        end

        def truncate!
          client.delete_by_query(
            index: index_name,
            body: { query: { match_all: {} } },
            conflicts: 'proceed',
            refresh: refresh?,
          )
        end

        private

        attr_reader :client

        def refresh?
          # impacts performance so should be used only in TEST env
          Rails.env.test?
        end

        def single(result)
          id = result['_id'].then { |i| i.to_i.positive? ? i.to_i : i }
          result['_source'].merge(id: id).deep_symbolize_keys
        end

        def multiple(results)
          docs = results.dig('hits', 'hits').map { |doc| single(doc) }
          { docs: docs }
        end

        def match_params(params)
          params.map { |(key, value)| { match: { key => value } } }
        end

        def index_name
          self.class.index_name
        end
      end
    end
  end
end
