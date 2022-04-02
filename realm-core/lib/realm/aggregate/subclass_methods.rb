# frozen_string_literal: true

module Realm
  class Aggregate
    module SubclassMethods
      def method_added(name)
        return if name.to_s.start_with?('_')
        return if instance_variable_defined?(:@redefined_command_methods) && @redefined_command_methods.include?(name)
        return if instance_variable_defined?(:@command_methods) && !@command_methods.include?(name)

        alias_method "_#{name}", name

        (@redefined_command_methods ||= []) << name

        redefine_method(name) do |*args, **kwargs|
          root.transaction do
            send("_#{name}", *args, **kwargs)
          end
          nil
        end
      end
    end
  end
end
