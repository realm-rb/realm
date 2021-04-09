# frozen_string_literal: true

require 'spec_helper'
require 'realm/command_handler'
require 'realm/runtime'
require_relative 'support/runtime_mock'

module CommandHandlerSpec
  class TestCommandHandler < Realm::CommandHandler
    def handle(param1:)
      run :foo, param1: param1
    end

    def another(param1:)
      trigger :bar, param1: param1
    end
  end
end

RSpec.describe Realm::CommandHandler do
  let(:runtime) { RuntimeMock.new }
  subject { CommandHandlerSpec::TestCommandHandler.new(runtime: runtime) }

  it 'can run other commands' do
    expect(runtime).to receive(:run).with('foo', param1: 'foo')
    subject.(params: { param1: 'foo' })
  end

  it 'can trigger events' do
    expect(runtime).to receive(:trigger).with(
      :bar, param1: 'bar', head: { origin: 'CommandHandlerSpec::TestCommandHandler#another' }
    )
    subject.(action: :another, params: { param1: 'bar' })
  end
end
