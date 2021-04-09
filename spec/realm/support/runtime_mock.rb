# frozen_string_literal: true

require 'realm/runtime'
require 'realm/context'
require_relative 'null_domain_resolver'

class RuntimeMock < Realm::Runtime
  def initialize(domain_resolver: NullDomainResolver.new, context: {}, **options)
    context = context.is_a?(Realm::Context) ? context : Realm::Context.new(context)
    super(domain_resolver: domain_resolver, context: context, **options)
  end
end
