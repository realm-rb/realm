# frozen_string_literal: true

module SampleApp
  module Relations
    class Reviews < ROM::Relation[:sql]
      schema :reviews, infer: true
    end
  end
end
