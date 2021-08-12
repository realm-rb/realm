# frozen_string_literal: true

module SampleAppNamespaced
  module Relations
    class Reviews < ROM::Relation[:sql]
      schema :reviews, infer: true
    end
  end
end
