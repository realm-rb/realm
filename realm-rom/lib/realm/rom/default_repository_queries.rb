# frozen_string_literal: true

module Realm
  module ROM
    module DefaultRepositoryQueries
      def find(id = nil, **conditions)
        root.where({ id: id, **conditions }.compact).one!
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
