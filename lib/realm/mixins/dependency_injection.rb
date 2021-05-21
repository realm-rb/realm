# frozen_string_literal: true

require 'realm/error'

module Realm
  module Mixins
    module DependencyInjection
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def new(*args, **kwargs, &block)
          injecting_names = @injecting.keys
          injecting_names.each do |name|
            define_method(name) do
              kwargs[name]
            end
            protected name
          end

          super(*args, **kwargs.reject { |k, _| injecting_names.include?(k) }, &block)
        end

        def inject(*things, as: nil)
          # do I need block like in ContextInjection?
          (@injecting ||= {}).merge!(things.map { |t| [as || t, t] }.to_h)
        end

        def dependencies
          @injecting.clone
        end
      end
    end
  end
end
