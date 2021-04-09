# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext/module/delegation'
require 'realm/action_handler'
require_relative 'support/runtime_mock'

class SampleOperation < Realm::ActionHandler
  def handle(params)
    params
  end

  def another(params)
    [:another, params]
  end
end

class DelegatedOperation < Realm::ActionHandler
  delegate :with_arguments, :with_keyword_arguments, :without_arguments, to: :target

  class Target
    def with_arguments(params)
      params
    end

    def with_keyword_arguments(param1:, _param2: nil)
      { param1: param1 }
    end

    def without_arguments
      'look mum no arguments'
    end
  end

  def target
    Target.new
  end
end

class OperationWithInjection < Realm::ActionHandler
  inject :dep1, :dep2

  def handle
    { dep1: dep1, dep2: dep2 }
  end
end

class OperationWithContract < Realm::ActionHandler
  contract do
    params do
      required(:param1).filled(:string)
    end
  end

  def handle(params)
    params
  end

  contract_json do
    required(:param1).filled(:integer)
  end

  def another(params)
    [:another, params]
  end
end

RSpec.describe Realm::ActionHandler do
  describe '.call' do
    it "calls handle method by default and returns it's result" do
      expect(SampleOperation.(params: { param1: 'value' })).to eq(param1: 'value')
    end

    it "calls method based on action argument and returns it's result" do
      expect(SampleOperation.(action: :another, params: { param1: 'value' })).to eq([:another, { param1: 'value' }])
    end

    context 'with delegation' do
      it 'works for method with arguments' do
        expect(DelegatedOperation.(action: :with_arguments, params: { param1: 'value' })).to eq(param1: 'value')
      end

      it 'works for method with keyword arguments' do
        expect(DelegatedOperation.(action: :with_keyword_arguments, params: { param1: 'value' })).to eq(param1: 'value')
      end

      it 'works for method without arguments' do
        expect(DelegatedOperation.(action: :without_arguments)).to eq('look mum no arguments')
      end
    end
  end

  describe '.inject' do
    it 'injects dependencies from context' do
      result = OperationWithInjection.(runtime: RuntimeMock.new(context: { dep1: 1, dep2: 2 }))
      expect(result).to eq(dep1: 1, dep2: 2)
    end
  end

  describe '.contract' do
    it 'raises InvalidParams error if contract not fulfilled' do
      expect { OperationWithContract.() }.to raise_error(Realm::InvalidParams, /is missing/)
      expect { OperationWithContract.(params: { param1: '' }) }.to raise_error(
        Realm::InvalidParams, /must be filled/
      )
      expect { OperationWithContract.(params: { param1: 7 }) }.to raise_error(
        Realm::InvalidParams, /must be a string/
      )
      expect { OperationWithContract.(action: :another, params: { param1: 'text' }) }.to raise_error(
        Realm::InvalidParams, /must be an integer/
      )
    end
  end
end
