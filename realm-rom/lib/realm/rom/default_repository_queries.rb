# frozen_string_literal: true

module Realm
  module ROM
    module DefaultRepositoryQueries
      def find(id_or_conditions)
        conditions = id_or_conditions.is_a?(Hash) ? id_or_conditions : { id: id_or_conditions }
        root.where(conditions).one!
      end

      def first(conditions = {})
        root.where(conditions).first
      end

      def last(conditions = {})
        root.where(conditions).last
      end

      def all(conditions = {})
        root.where(conditions).to_a
      end
    end
  end
end
