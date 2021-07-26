# frozen_string_literal: true

module Realm
  module ROM
    module DefaultRepositoryQueries
      def find(id = nil, **conditions)
        root.where({ id: id, **conditions }.compact).one!
      end

      def first(conditions = {})
        root.where(conditions).one
      end

      def all(conditions = {})
        root.where(conditions).to_a
      end
    end
  end
end
