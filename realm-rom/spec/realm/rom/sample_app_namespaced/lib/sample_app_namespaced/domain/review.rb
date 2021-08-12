# frozen_string_literal: true

module SampleAppNamespaced
  module Domain
    module Review
      class CreateCommandHandler < Realm::CommandHandler
        inject :review_repo

        def handle(text:)
          review_repo.create(text: text)
        end
      end

      class QueryHandlers < Realm::QueryHandler
        use_repo

        def all
          review_repo.all
        end
      end
    end
  end
end
