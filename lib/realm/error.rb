# frozen_string_literal: true

module Realm
  class Error < StandardError
    def self.[](default_msg)
      Class.new(Realm::Error) do
        define_method(:initialize) do |msg = default_msg|
          super(msg)
        end
      end
    end
  end

  class QueryHandlerMissing < Error
    def initialize(query_name, msg: "Cannot find handler for query '#{query_name}'")
      super(msg)
    end
  end

  class CommandHandlerMissing < Error
    def initialize(command_name, msg: "Cannot find handler for command '#{command_name}'")
      super(msg)
    end
  end

  class CannotHandleAction < Error
    def initialize(handler, action, msg: "#{handler} cannot handle action '#{action}'")
      super(msg)
    end
  end

  class DependencyMissing < Error
    def initialize(dependency_name, msg: "There is no '#{dependency_name}' in context object")
      super(msg)
    end
  end

  class EventClassMissing < Error
    def initialize(identifier, events_module, msg: "Cannot find event class for #{identifier} in #{events_module}")
      super(msg)
    end
  end

  class InvalidParams < Error
    def initialize(validation_result, msg: "Validation failed: #{validation_result.errors.to_h}")
      @validation_result = validation_result
      super(msg)
    end

    def params
      @validation_result.to_h
    end

    def messages
      @validation_result.errors.to_h
    end

    def full_messages
      @validation_result.errors(full: true).to_h
    end
  end
end
