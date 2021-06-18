# frozen_string_literal: true

module SampleApp
  module Repositories
    class Review < Realm::ROM::Repository[:reviews]
      commands :create

      def all
        reviews.to_a
      end
    end
  end
end
