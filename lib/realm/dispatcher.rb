# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'realm/query_handler'
require 'realm/command_handler'
require 'realm/errors'
require 'realm/persistence/repository_query_handler_adapter'

module Realm
  class Dispatcher
    def initialize(domain_resolver:, runtime: nil)
      @domain_resolver = domain_resolver
      @runtime = runtime
      @threads = []
    end

    def fork(runtime)
      self.class.new(domain_resolver: @domain_resolver, runtime: runtime)
    end

    def query(identifier, params = {})
      callable, action = get_callable(QueryHandler, identifier)
      callable, action = get_repo_adapter(identifier) unless callable
      raise QueryHandlerMissing, identifier unless callable

      dispatch(callable, action, params)
    end

    def run(identifier, params = {})
      callable, action = get_callable(CommandHandler, identifier)
      raise CommandHandlerMissing, identifier unless callable

      dispatch(callable, action, params)
    end

    def run_as_job(identifier, params = {})
      callable, action = get_callable(CommandHandler, identifier)
      raise CommandHandlerMissing, identifier unless callable

      @threads.delete_if(&:stop?)
      @threads << Thread.new do # TODO: back by SQS
        result = dispatch(callable, action, params)
        yield result if block_given?
      end
    end

    # Blocks until all jobs are finished. Useful mainly in tests.
    def wait_for_jobs
      @threads.each(&:join)
    end

    private

    def dispatch(callable, action, params)
      arguments = { action: action, params: params, runtime: @runtime }.compact
      callable.(**arguments)
    end

    def get_callable(type, identifier)
      return [identifier, nil] if identifier.respond_to?(:call)

      @domain_resolver.get_handler_with_action(type, identifier)
    end

    def get_repo_adapter(identifier)
      parts = identifier.to_s.split('.')
      return [nil, nil] unless parts.size == 2 && @runtime&.context&.key?("#{parts[0]}_repo")

      [Persistence::RepositoryQueryHandlerAdapter.new(@runtime.context["#{parts[0]}_repo"]), parts[1].to_sym]
    end
  end
end
