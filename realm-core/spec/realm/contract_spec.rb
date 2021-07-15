# frozen_string_literal: true

class StandardContract < Realm::Contract
  schema do
    required(:foo).filled(:string)
  end
end

MyStruct = Realm.Struct(
  foo: Realm::Types::String,
  bar: Realm::Types::Array.of(Realm.Struct(baz: Realm::Types::Integer)),
)

class StructContract < Realm::Contract
  params MyStruct
end

class AttributesContract < Realm::Contract
  json foo: Realm::Types::Integer
end

RSpec.describe Realm::Contract do
  it 'supports standard dry-validation use-case' do
    standard_contract = StandardContract.new
    expect(standard_contract.({})).to be_a(Dry::Validation::Result)
    expect(standard_contract.(foo: 'text').to_h).to eq(foo: 'text')
  end

  it 'supports schema defined by struct' do
    struct_contract = StructContract.new
    expect(struct_contract.({})).to be_a(Dry::Validation::Result)
    expect(struct_contract.(foo: 'text', bar: [{ baz: 1 }]).to_h).to eq(foo: 'text', bar: [{ baz: 1 }])
  end

  it 'supports schema defined by struct attributes' do
    attributes_contract = AttributesContract.new
    expect(attributes_contract.({})).to be_a(Dry::Validation::Result)
    expect(attributes_contract.(foo: 1).to_h).to eq(foo: 1)
  end
end
