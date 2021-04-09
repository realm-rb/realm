# frozen_string_literal: true

class NullDomainResolver
  def initialize(*); end

  def get_handler_with_action(*)
    [nil, nil]
  end

  def all_event_handlers
    []
  end
end
