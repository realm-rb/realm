# frozen_string_literal: true

require 'realm-core'
require 'realm-elasticsearch'
require 'elasticsearch'

module TestIntegrationService
  module Repositories
    class Review < Realm::Elasticsearch::Repository; end
  end

  module Domain
    module Review
      class CreateCommandHandler < Realm::CommandHandler
        inject :review_repo

        def handle(text:, id: nil)
          review_repo.create(id: id, text: text)
        end
      end
    end
  end
end

RSpec.describe 'Integration of Elasticsearch plugin with realm core' do
  let(:es_client) { Elasticsearch::Client.new(url: ENV.fetch('ELASTICSEARCH_URL')) }
  let(:realm) do
    Realm.setup(
      TestIntegrationService,
      plugins: :elasticsearch,
      engine_class: nil,
      persistence_gateway: {
        type: :elasticsearch,
        url: ENV.fetch('ELASTICSEARCH_URL'),
        repositories: [TestIntegrationService::Repositories::Review],
      },
    ).runtime
  end

  before do
    es_client.indices.create(index: 'reviews')
  end

  after do
    es_client.indices.delete(index: 'reviews')
  end

  it 'works for happy path' do
    realm.run('review.create', text: 'Awesome')
    realm.run('review.create', id: 123, text: 'Int ID doc')

    expect(realm['review_repo'].all[:docs]).to include(
      { id: kind_of(String), text: 'Awesome' },
      { id: 123, text: 'Int ID doc' },
    )
  end
end
