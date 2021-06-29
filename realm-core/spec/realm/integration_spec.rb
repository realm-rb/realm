# frozen_string_literal: true

require 'ostruct'
require 'realm'

module TestIntegrationService
  module Domain
    module Submission
      class QueryHandlers < Realm::QueryHandler
        inject :submission_repo
        delegate :all, to: :submission_repo
      end

      module CommandHandlers
        class Create < Realm::CommandHandler
          inject :submission_repo

          contract do
            params do
              required(:general_comments).filled(:string)
            end
          end

          def handle(params)
            entity = submission_repo.create(general_comments: params[:general_comments])
            event = trigger(:submission_created, submission_id: entity.id)
            result event, entity
          end
        end

        class Publish < Realm::CommandHandler
          def handle(submission_id:, **)
            trigger('custom_scoped.submission_published', submission_id: submission_id)
          end
        end
      end

      class SampleEventHandler < Realm::EventHandler
        inject :event_log

        on :submission_created
        def handle_submission_created(event)
          event_log << event
          run :publish, event.body
        end

        on 'custom_scoped.submission_published'
        def handle_submission_published(event)
          event_log << event
        end
      end
    end

    module Events
      class SubmissionCreated < Realm::Event
        body_struct do
          attribute :submission_id, T::Integer
        end
      end

      class SubmissionPublished < Realm::Event
        def self.type
          'custom_scoped.submission_published'
        end

        body_struct do
          attribute :submission_id, T::Integer
        end
      end
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

  RSpec.describe 'Realm integration:' do
    let(:submission_repo) { SubmissionRepo.new }
    let(:event_log) { [] }
    let(:dependencies) { { submission_repo: submission_repo, event_log: event_log } }
    let(:realm) do
      Realm.setup(
        TestIntegrationService,
        engine_class: nil,
        dependencies: dependencies,
        event_gateway: { type: :internal_loop, events_module: Domain::Events, isolated: true },
      ).runtime
    end

    it 'works for happy path' do
      created_event, entity = realm.run('submission.create', general_comments: 'Awesome')
      expect(created_event.class).to eq(Domain::Events::SubmissionCreated)
      expect(created_event.head.correlation_id).to be_present
      expect(created_event.body.submission_id).to eq(1)
      expect(entity.id).to eq(1)
      expect(entity.general_comments).to eq('Awesome')

      submissions = realm.query('submission.all')
      expect(submissions.size).to eq(1)
      expect(submissions[0].id).to eq(1)
      expect(submissions[0].general_comments).to eq('Awesome')

      expect(event_log.size).to eq(2)
      expect(event_log[0]).to eq(created_event)
      expect(event_log[0].body.submission_id).to eq(1)
      expect(event_log[1]).to be_a(Domain::Events::SubmissionPublished)
      expect(event_log[1].head.cause_event_id).to eq(created_event.head.id)
      expect(event_log[1].head.correlation_id).to eq(created_event.head.correlation_id)
      expect(event_log[1].body.submission_id).to eq(1)
    end

    describe 'unknown query' do
      it 'raises Realm::QueryHandlerMissing' do
        expect { realm.query('foo') }.to raise_error(Realm::QueryHandlerMissing)
      end
    end

    describe 'unknown command' do
      it 'raises Realm::CommandHandlerMissing' do
        expect { realm.run('foo') }.to raise_error(Realm::CommandHandlerMissing)
        expect { realm.run('submission.foo') }.to raise_error(Realm::CommandHandlerMissing)
      end
    end

    describe 'existing multi handler but unknown action' do
      it 'raises Realm::CannotHandleAction' do
        expect { realm.query('submission.foo') }.to raise_error(Realm::CannotHandleAction)
      end
    end

    describe 'invalid command params' do
      it 'raises Realm::InvalidParams' do
        expect { realm.run('submission.create') }.to raise_error do |err|
          expect(err).to be_a(Realm::InvalidParams)
          expect(err.messages).to eq(general_comments: ['is missing'])
        end
        expect(event_log.size).to eq(0)
      end
    end
  end
end
