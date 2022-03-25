# frozen_string_literal: true

module Realm
  class DomainResolver
    DOMAIN_CLASS_TYPES = [CommandHandler, QueryHandler, EventHandler].freeze

    def initialize(domain_module = nil)
      # nil domain resolver is useful in tests
      @domain_module = domain_module
      @index = DOMAIN_CLASS_TYPES.to_h { |t| [t, {}] }
      scan(domain_module) if domain_module
    end

    def get_handler_with_action(type, identifier)
      handlers = @index[type]
      return [handlers[identifier], :handle] if handlers.key?(identifier)

      # The last part of the identifier can be action method name inside the handler
      parts = identifier.split('.')
      handler_part = parts[..-2].join('.')
      action = parts[-1]
      return [handlers[handler_part], action.to_sym] if handlers.key?(handler_part)

      [nil, nil]
    end

    def all_event_handlers
      @index[EventHandler].values
    end

    private

    def scan(root_module)
      root_module_str = root_module.to_s
      root_module.constants.each do |const_sym|
        const = root_module.const_get(const_sym)
        next unless const.is_a?(Module) && !(const < Event) && const.to_s.start_with?(root_module_str)

        type = DOMAIN_CLASS_TYPES.find { |t| const < t }
        next scan(const) unless type

        register(type, const)
      end
    end

    def register(type, const)
      # Remove domain module prefix and handler type suffixes
      operation_type = type.to_s.demodulize.sub('Handler', '')
      identifier = const.to_s.gsub(/(^#{@domain_module})|((#{operation_type})?Handlers?)/, '')
      @index[type][identifier.underscore.gsub(%r{(^/+)|(/+$)}, '').gsub(%r{/+}, '.')] = const
    end
  end
end
