# frozen_string_literal: true

require 'realm/runtime'
require 'realm/context'
require_relative 'null_domain_resolver'

class RuntimeMock < Realm::Runtime
  def initialize(domain_resolver: NullDomainResolver.new, context: {}, **options)
    context = Realm::Context.new(context, default_dependencies) unless context.is_a?(Realm::Context)
    super(domain_resolver: domain_resolver, context: context, **options)
  end

  private

  def default_dependencies
    { logger: Logger.new($stdout, level: ENV.fetch('LOG_LEVEL', :info).to_sym) }
  end
end
