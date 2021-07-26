# frozen_string_literal: true

module RomRepositoryTest
  class Things < ROM::Relation[:sql]
    schema(:things, infer: true)
  end

  class ThingRepo < Realm::ROM::Repository[:things]
    commands :create
    queries :default
  end
end

RSpec.describe Realm::ROM::Repository do
  let(:rom) do
    ROM.container(:sql, 'sqlite::memory') do |conf|
      conf.default.create_table(:things) do
        primary_key :id
        column :name, String, null: false
      end
      conf.register_relation(RomRepositoryTest::Things)
    end
  end
  let(:thing_repo) { RomRepositoryTest::ThingRepo.new(rom) }

  describe '.queries' do
    it 'expose default queries' do
      foo = thing_repo.create(name: 'foo')
      bar = thing_repo.create(name: 'bar')

      expect(thing_repo.all).to eq([foo, bar])
      expect(thing_repo.all(name: 'bar')).to eq([bar])
      expect(thing_repo.all(name: 'baz')).to eq([])

      expect(thing_repo.first(name: 'bar')).to eq(bar)
      expect(thing_repo.first(name: 'baz')).to eq(nil)

      expect(thing_repo.find(name: 'bar')).to eq(bar)
      expect(thing_repo.find(id: foo.id)).to eq(foo)
      expect { thing_repo.find(name: 'baz') }.to raise_error
    end
  end
end
