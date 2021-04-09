# frozen_string_literal: true

module Realm
  module Mixins
    module AggregateMember
      def self.included(base)
        base.extend(ClassMethods)
      end

      def aggregate
        self.class.aggregate
      end

      module ClassMethods
        def aggregate
          @aggregate ||= begin
            module_chain = name.split('::')
            domain_index = module_chain.index('Domain')
            domain_index && module_chain[domain_index + 1].underscore.to_sym
          end
        end
      end
    end
  end
end
