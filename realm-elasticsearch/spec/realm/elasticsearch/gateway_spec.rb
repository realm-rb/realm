# frozen_string_literal: true

module ElasticsearchGatewayTest
  class Review < Realm::Elasticsearch::Repository; end
end

RSpec.describe Realm::Elasticsearch::Gateway do
  let(:es_client) { Elasticsearch::Client.new(url: ENV.fetch('ELASTICSEARCH_URL')) }

  describe '#health' do
    context 'with wrong ES url' do
      subject do
        described_class.new(url: 'http://wrong:9200')
      end

      it 'returns red status' do
        health = subject.health
        expect(health.code).to eq(:red)
        expect(health.issues[0]).to match(/^Elasticsearch connection error/)
      end
    end

    context 'with correct ES url' do
      subject do
        described_class.new(url: ENV.fetch('ELASTICSEARCH_URL'))
      end

      context 'with missing index' do
        it 'returns red status' do
          health = subject.health
          expect(health.code).to eq(:red)
          expect(health.issues).to include('One or more indexes missing')
        end
      end

      context 'with existing index' do
        before do
          es_client.indices.create(index: 'reviews')
        end

        after do
          es_client.indices.delete(index: 'reviews')
        end

        it 'returns green status' do
          health = subject.health
          expect(health.code).to eq(:green)
        end
      end
    end
  end
end
