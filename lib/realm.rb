# frozen_string_literal: true

Dir[File.join(File.dirname(__FILE__), 'realm', '**', '*.rb')].sort.each do |f|
  require f
end

module Realm
  class << self
    # Setup realm in test/console
    def setup(root_module, **options)
      Realm::Builder.setup(root_module, **options)
    end

    # Bind realm in service/engine
    def bind(root_module, **options)
      setup(root_module, **options).tap do |builder|
        root_module.define_singleton_method(:realm) { builder.runtime }
      end
    end
  end
end
