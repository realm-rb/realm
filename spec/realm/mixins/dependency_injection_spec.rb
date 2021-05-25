# frozen_string_literal: true

require 'spec_helper'
require 'realm/container'
require 'realm/mixins/dependency_injection'

module DependencyInjectionSpec
  class WithDI
    include Realm::Mixins::DependencyInjection
  end

  class Simple < WithDI
    inject :foo, 'bar'
  end

  class Foo
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class Bar < WithDI
    inject Foo, as: :my_foo
    attr_reader :value

    def initialize(value:)
      super()
      @value = value
    end

    def foo_value
      my_foo.value
    end
  end

  class Baz < WithDI
    inject 'DependencyInjectionSpec::Foo'
    attr_reader :value

    def foo_value
      foo.value
    end
  end

  class Lazy < WithDI
    inject Foo, lazy: true
  end

  class Optional < WithDI
    inject Foo, optional: true
  end

  class Circular1 < WithDI
    inject 'DependencyInjectionSpec::Circular2'
  end

  class Circular2 < WithDI
    inject 'DependencyInjectionSpec::Circular1', lazy: true
  end
end

RSpec.describe Realm::Mixins::DependencyInjection do
  let(:container) { Realm::Container.new }

  describe '.inject' do
    context 'with symbol or string' do
      it 'injects dependency from container' do
        container.register(:foo, 123)
        container.register(:bar, 456)
        simple = container.create(DependencyInjectionSpec::Simple)
        expect(simple.send(:foo)).to eq 123
        expect(simple.send(:bar)).to eq 456
      end
    end

    context 'with class constant' do
      it 'injects instance of given class from container' do
        container.register_factory(DependencyInjectionSpec::Foo, 123)
        bar = container.create(DependencyInjectionSpec::Bar, value: 456)
        expect(bar.value).to eq 456
        expect(bar.foo_value).to eq 123
      end
    end

    context 'with class name in string' do
      it 'injects instance of given class from container' do
        container.register_factory(DependencyInjectionSpec::Foo, 123)
        baz = container.create(DependencyInjectionSpec::Baz)
        expect(baz.foo_value).to eq 123
      end
    end

    context 'with class name in string and lazy option' do
      it 'allows injecting circular dependencies' do
        container.register_factory(DependencyInjectionSpec::Circular1)
        container.register_factory(DependencyInjectionSpec::Circular2)
        circular2 = container.resolve(DependencyInjectionSpec::Circular2)
        expect(circular2.send(:circular1)).to eq container.resolve(DependencyInjectionSpec::Circular1)
      end
    end

    context 'missing dependency' do
      it 'raises DependencyMissing on initialization' do
        expect { container.create(DependencyInjectionSpec::Bar) }.to raise_error(Realm::DependencyMissing)
      end

      context 'with lazy option' do
        it 'raises DependencyMissing when dependency is first called' do
          lazy = container.create(DependencyInjectionSpec::Lazy)
          expect { lazy.send(:foo) }.to raise_error(Realm::DependencyMissing)
        end
      end

      context 'with optional option' do
        it 'injector method returns nil if dependency is not present in container' do
          optional = container.create(DependencyInjectionSpec::Optional)
          expect(optional.send(:foo)).to eq nil
        end
      end
    end
  end
end
