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
end
