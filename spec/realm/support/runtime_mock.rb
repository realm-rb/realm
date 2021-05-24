# frozen_string_literal: true

require 'realm/runtime'
require 'realm/container'
# require_relative 'null_domain_resolver'

class RuntimeMock < Realm::Runtime
  def initialize(context: {})
    super(Realm::Container[default_dependencies.merge(context)])
  end

  private

  def default_dependencies
    { logger: Logger.new($stdout, level: ENV.fetch('LOG_LEVEL', :info).to_sym) }
  end
end
