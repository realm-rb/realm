# frozen_string_literal: true

require 'ostruct'
require 'active_support/core_ext/module/remove_method'
require 'realm'

module TestMixinsControllerService
  module Domain
    module Submission
      class QueryHandlers < Realm::QueryHandler
        inject :submission_repo
        delegate :all, to: :submission_repo
      end

      class CommandHandlers < Realm::CommandHandler
        inject :submission_repo

        contract do
          params do
            required(:general_comments).filled(:string)
          end
        end

        def create(params)
          result submission_repo.create(general_comments: params[:general_comments])
        end
      end
    end
  end

  class SampleController
    include Realm::Mixins::Controller

    with_aggregate :submission

    def show
      query(:all)
    end

    def submit(params)
      entity = run(:create, params).value
      "Submission entity ##{entity.id} created"
    end
  end

  class SubmissionRepo
    def initialize
      @submissions = []
      @id_counter = 0
    end

    def all
      @submissions
    end

    def create(**attributes)
      @id_counter += 1
      entity = OpenStruct.new(id: @id_counter, **attributes)
      @submissions << entity
      entity
    end
  end

  RSpec.describe ::Realm::Mixins::Controller do
    let(:submission_repo) { SubmissionRepo.new }
    let(:dependencies) { { submission_repo: submission_repo } }
    let(:controller) { SampleController.new }

    before do
      TestMixinsControllerService.remove_possible_singleton_method(:realm)
      Realm.bind(TestMixinsControllerService, dependencies: dependencies, engine_class: nil, resolver: nil)
    end

    it 'works for happy path' do
      notification = controller.submit(general_comments: 'Awesome')

      expect(submission_repo.all.size).to eq(1)
      expect(notification).to eq('Submission entity #1 created')

      entries = controller.show
      expect(entries.size).to eq(1)
      expect(entries[0].id).to eq(1)
      expect(entries[0].general_comments).to eq('Awesome')
    end

    it 'raises exception for invalid input' do
      expect { controller.submit(general_comments: nil) }.to raise_error(Realm::InvalidParams)
    end
  end
end
