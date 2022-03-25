# frozen_string_literal: true

module SetupSpec
  class Realm < Realm::Setup
    prefix 'my-prefix'
    logger :logger1
    plug :plugin1, foo: 12, bar: 'value'
    plug :plugin2, baz: 34
    register :service1, :service1_payload
  end

  class AnotherRealm < SetupSpec::Realm
    logger :logger2
    unplug :plugin2
    register :service2, :service2_payload
  end
end

RSpec.describe Realm::Setup do
  let(:expected_options) do
    {
      prefix: 'my-prefix',
      logger: :logger2,
      plugins: [
        { name: :plugin1, foo: 12, bar: 'value' },
      ],
      dependencies: {
        service1: :service1_payload,
        service2: :service2_payload,
      },
    }
  end

  describe '.init' do
    it 'calls Realm.setup with correct options' do
      expect(Realm).to receive(:setup).with(SetupSpec, expected_options)
      SetupSpec::AnotherRealm.init
    end
  end

  describe '.bind' do
    it 'calls Realm.bind with correct options' do
      expect(Realm).to receive(:bind).with(SetupSpec, expected_options)
      SetupSpec::AnotherRealm.bind
    end
  end
end
