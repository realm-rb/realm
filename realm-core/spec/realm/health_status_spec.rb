# frozen_string_literal: true

RSpec.describe Realm::HealthStatus do
  describe '.[]' do
    it 'creates instance for valid code' do
      described_class::CODES.each do |code|
        expect(described_class[code].code).to eq(code)
      end
    end

    it 'creates instance for valid code with issues' do
      described_class::CODES.each do |code|
        health = described_class[code, 'Issue1', 'Issue2']
        expect(health.code).to eq(code)
        expect(health.issues).to eq(%w[Issue1 Issue2])
      end
    end

    it 'raises error for invalid code ' do
      expect { described_class[:foo] }.to raise_error(ArgumentError)
    end
  end

  describe '.from_issues' do
    it 'creates instance with status code based on issues presence' do
      expect(described_class.from_issues([]).code).to eq(:green)
      expect(described_class.from_issues(['An issue']).code).to eq(:red)
    end
  end

  describe '.combine' do
    it 'combines multiple components health status' do
      health = described_class.combine(foo: described_class[:green], bar: described_class[:yellow])
      expect(health.code).to eq(:yellow)
      expect(health.for_component(:foo).code).to eq(:green)
      expect(health.for_component(:bar).code).to eq(:yellow)
    end
  end

  describe '#to_h' do
    it 'returns health status tree' do
      health = described_class.combine(
        foo: described_class[:yellow, 'Issue1'],
        bar: described_class.combine(zoo: described_class[:red, 'Issue2', 'Issue3']),
      )
      expect(health.to_h).to eq(
        status: :red,
        components: {
          foo: {
            status: :yellow,
            issues: %w[Issue1],
          },
          bar: {
            status: :red,
            components: {
              zoo: {
                status: :red,
                issues: %w[Issue2 Issue3],
              },
            },
          },
        },
      )
    end
  end
end
