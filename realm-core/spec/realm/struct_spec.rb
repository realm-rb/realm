# frozen_string_literal: true

class SampleStruct < Realm::Struct
  attributes(
    a_scalar: Realm::Types::Integer,
    a_struct?: Realm.Struct(foo: Realm::Types::Integer),
    an_array_of_scalar?: Realm::Types::Array.of(Realm::Types::Integer),
    an_array_of_struct?: Realm::Types::Array.of(Realm.Struct(bar: Realm::Types::Integer)),
  )
end

RSpec.describe Realm::Struct do
  describe '.to_dry_schema' do
    let(:schema) { SampleStruct.to_dry_schema }

    it 'generates correct dry schema' do
      expect(schema.(a_scalar: 1)).to be_a(Dry::Schema::Result)
      expect(schema.(a_scalar: 1).to_h).to eq(a_scalar: 1)
      expect(schema.(a_scalar: 1, a_struct: { foo: 2 }).to_h).to eq(a_scalar: 1, a_struct: { foo: 2 })
      expect(schema.(a_scalar: 1, an_array_of_scalar: [2, 3]).to_h).to include(an_array_of_scalar: [2, 3])
      expect(schema.(a_scalar: 1, an_array_of_struct: [{ bar: 2 }]).to_h).to include(an_array_of_struct: [{ bar: 2 }])

      expect(schema.({}).errors.to_h).to eq(a_scalar: ['is missing'])

      payload = {
        a_scalar: 'text1',
        a_struct: 1,
        an_array_of_scalar: ['text2'],
        an_array_of_struct: [{ bar: 'text3' }],
      }
      expect(schema.(payload).errors.to_h).to eq(
        a_scalar: ['must be an integer'],
        a_struct: ['must be a hash'],
        an_array_of_scalar: { 0 => ['must be an integer'] },
        an_array_of_struct: { 0 => { bar: ['must be an integer'] } },
      )
    end
  end
end
