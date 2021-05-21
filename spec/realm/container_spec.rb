# frozen_string_literal: true

require 'spec_helper'
require 'realm/container'
require 'realm/mixins/dependency_injection'

module ContainerSpec
  class Foo
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class Bar
    include Realm::Mixins::DependencyInjection
    attr_reader :value
    inject Foo, as: :foo

    def initialize(value:)
      @value = value
    end

    def foo_value
      foo.value
    end
  end
end

RSpec.describe Realm::Container do
  describe 'dependency injection' do
    it 'works for class instances' do
      subject.register(ContainerSpec::Foo, 123)
      subject.register(ContainerSpec::Bar, value: 456)

      bar = subject.resolve(ContainerSpec::Bar)
      expect(bar.value).to eq 456
      expect(bar.foo_value).to eq 123
    end
  end
end
