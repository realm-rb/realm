# frozen_string_literal: true

require 'realm/runtime'
require 'realm/query_handler'
require 'realm/mixins/repository_helper'

module TestMixinsRepositoryHelper
  module Domain
    module Sample
      class QueryHandlers < Realm::QueryHandler
        use_repo

        def read
          sample_repo.all
        end

        def write
          sample_repo.create(name: 'foo')
        end
      end
    end
  end

  class ThingRepo
    def initialize(things = [], readonly: false)
      @things = things
      @readonly = readonly
    end

    def all
      @things
    end

    def create(thing)
      raise 'Readonly' if @readonly

      @things << thing
    end

    def readonly
      self.class.new(@things, readonly: true)
    end
  end

  RSpec.describe Realm::Mixins::RepositoryHelper do
    context 'for query handler' do
      let(:thing_repo) { ThingRepo.new.tap { |r| r.create(name: 'box') } }
      let(:runtime) { Realm::Runtime.new(sample_repo: thing_repo) }

      it 'auto injects repo' do
        expect(Domain::Sample::QueryHandlers.(action: :read, runtime: runtime)).to eq([{ name: 'box' }])
      end

      it 'auto injects repo in readonly mode if supported' do
        expect { Domain::Sample::QueryHandlers.(action: :write, runtime: runtime) }.to raise_error('Readonly')
      end
    end

    context 'for custom class' do
      let(:base_mock_class) do
        Class.new do
          include Realm::Mixins::RepositoryHelper

          class << self
            attr_reader :write_repos, :read_repos

            def aggregate
              :foo
            end

            def inject(name)
              if block_given?
                (@read_repos ||= []) << name.to_sym
              else
                (@write_repos ||= []) << name.to_sym
              end
            end
          end
        end
      end

      it 'raises error if class does not respond to aggregate' do
        expect {
          Class.new do
            include Realm::Mixins::RepositoryHelper
            use_repo
          end
        }.to raise_error(/outside of an aggregate/)
      end

      it 'raises error if attempting to use two write repos in one call' do
        expect {
          Class.new(base_mock_class) do
            use_repo :foo, :bar
          end
        }.to raise_error(%r{only one read/write repo})
      end

      it 'raises error if attempting to use two write repos in multiple calls' do
        expect {
          Class.new(base_mock_class) do
            use_repo :foo
            use_repo :bar
          end
        }.to raise_error(%r{only one read/write repo})
      end

      it 'injects single write repo named based on aggregate' do
        klass = Class.new(base_mock_class) do
          use_repo
        end
        expect(klass.write_repos).to eq([:foo_repo])
      end

      it 'injects single write and multiple read repos' do
        klass = Class.new(base_mock_class) do
          use_repo :foo2
          use_repo :bar, :zoo, readonly: true
        end
        expect(klass.write_repos).to eq(%i[foo2_repo])
        expect(klass.read_repos).to eq(%i[bar_repo zoo_repo])
      end
    end
  end
end
