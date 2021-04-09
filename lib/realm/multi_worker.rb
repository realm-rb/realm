# frozen_string_literal: true

module Realm
  class MultiWorker
    def initialize(workers = [])
      @workers = workers
    end

    def start(*args)
      @workers.each { |w| w.start(*args) }
      self
    end

    def stop(timeout: 30)
      @workers.each { |w| w.stop(timeout: timeout) }
    end

    def join
      @workers.each(&:join)
    end

    def run
      %w[INT TERM].each do |signal|
        Signal.trap(signal) { stop }
      end
      start
      join
    end
  end
end
