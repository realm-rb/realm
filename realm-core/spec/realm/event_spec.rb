# frozen_string_literal: true

module TestEvents
  class InternalStructEvent < Realm::Event
    body_struct do
      attribute :foo, T::String
    end
  end

  class MyStruct < Dry::Struct
    attribute :foo, Realm::Types::String
  end

  class ExternalStructEvent < Realm::Event
    body_struct MyStruct
  end

  class InlineStructEvent < Realm::Event
    body_struct Dry.Struct(foo: Realm::Types::String)
  end

  # This does not work but maybe it should, leaving it here for future reference
  # MyType = Realm::Types::Hash.schema(foo: Realm::Types::String)

  # class HashTypeEvent < Realm::Event
  #   body_struct MyType
  # end

  class EventWithMeta < Realm::Event
    body_struct do
      attribute :foo, T::String.meta(meta1: 'x', meta2: 2)
      attribute :another, T::Integer
      attribute :bar do
        attribute :inner, T::String.meta(meta3: 3)
      end
      attribute :baz, T::Array do
        attribute :member, T::String.meta(meta4: 4)
      end
    end
  end

  class FreeStructureEvent < Realm::Event
    attribute :body, Realm::Types::Hash
  end
end

RSpec.describe Realm::Event do
  describe 'definition' do
    it 'supports internal struct' do
      expect(TestEvents::InternalStructEvent.new(foo: 'hi').body.foo).to eq 'hi'
    end

    it 'supports external struct' do
      expect(TestEvents::ExternalStructEvent.new(foo: 'hi').body.foo).to eq 'hi'
    end

    it 'supports inline struct' do
      expect(TestEvents::InlineStructEvent.new(foo: 'hi').body.foo).to eq 'hi'
    end
  end

  describe '.attributes_with_meta' do
    it 'returns map from attribute path to meta values if present' do
      expect(TestEvents::EventWithMeta.attributes_with_meta).to eq(
        [:foo] => { meta1: 'x', meta2: 2 },
        %i[bar inner] => { meta3: 3 },
        %i(baz [] member) => { meta4: 4 },
      )
    end

    it 'handles free structure events' do
      expect(TestEvents::FreeStructureEvent.attributes_with_meta).to eq({})
    end
  end
end
