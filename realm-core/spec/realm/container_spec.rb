# frozen_string_literal: true

require 'realm/container'
require 'realm/dependency'

RSpec.describe Realm::Container do
  describe '[]' do
    it 'tries to turn object into container unless it already is' do
      container = described_class[foo: 123]
      expect(container).to be_a Realm::Container
      expect(container[:foo]).to eq 123

      container2 = described_class[container]
      expect(container2).to eq container
    end
  end

  describe '.new' do
    it 'registers all members of hash' do
      container = described_class.new(foo: 123)
      expect(container[:foo]).to eq 123
    end
  end

  describe '#register' do
    it 'registers value' do
      subject.register(:foo, 123)
      expect(subject[:foo]).to eq 123
    end
  end

  describe '#register_all' do
    it 'registers all members of hash' do
      subject.register_all(foo: 123)
      expect(subject[:foo]).to eq 123
    end
  end

  describe '#register_factory' do
    let(:klass) do
      Class.new do
        attr_reader :foo, :bar

        def initialize(foo, bar:)
          @foo = foo
          @bar = bar
        end
      end
    end

    it 'registers class instance factory' do
      subject.register_factory(klass, 'hi', bar: 123)
      instance = subject.resolve(klass)
      expect(instance).to be_a klass
      expect(instance.foo).to eq 'hi'
      expect(instance.bar).to eq 123

      expect(subject.resolve(klass)).to eq instance
    end

    context 'with memoize: false option' do
      it 'resolves each time new instance' do
        subject.register_factory(klass, 'hi', bar: 123, memoize: false)
        instance = subject.resolve(klass)
        expect(subject.resolve(klass)).not_to eq instance
      end
    end

    context 'with as: option' do
      it 'registers the class instance under alias' do
        subject.register_factory(klass, 'hi', bar: 123, as: 'my.foo')
        expect(subject.key?(klass)).to eq false
        expect(subject.resolve('my.foo')).to be_instance_of(klass)
      end
    end
  end

  describe '#create' do
    let(:klass) do
      Class.new do
        attr_reader :foo, :bar, :zoo

        def self.dependencies
          [Realm::Dependency.new(:bar)]
        end

        def initialize(foo, bar:, zoo:)
          @foo = foo
          @bar = bar
          @zoo = zoo
        end
      end
    end

    it 'creates class instance with injected dependencies' do
      subject.register(:bar, :i_am_dependency)
      instance = subject.create(klass, 'hi', zoo: 123)
      expect(instance).to be_a klass
      expect(instance.foo).to eq 'hi'
      expect(instance.bar).to eq :i_am_dependency
      expect(instance.zoo).to eq 123
    end
  end

  describe '#resolve_all' do
    let(:klass) { Class.new }
    let(:subclass) { Class.new(klass) }

    it 'returns all instances of class' do
      subject.register(:item1, klass.new)
      subject.register(:item2, subclass.new)
      subject.register_factory(klass)
      subject.register_factory(subclass)
      subject.register_factory(klass, as: :item3)
      subject.register_factory(subclass, as: :item4)

      instances = subject.resolve_all(klass)
      expect(instances.count).to eq 6
      expect(instances.all? { |i| i.is_a?(klass) }).to eq true

      instances = subject.resolve_all(subclass)
      expect(instances.count).to eq 3
      expect(instances.all? { |i| i.is_a?(subclass) }).to eq true
    end
  end
end
