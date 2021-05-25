# frozen_string_literal: true

require 'active_support/core_ext/string'

module Realm
  class Dependency
    attr_reader :dependable, :name

    def initialize(dependable, as: nil, optional: false, lazy: false) # rubocop:disable Naming/MethodParameterName
      @dependable = dependable
      @name = as || dependable.to_s.demodulize.underscore.to_sym
      @optional = optional
      @lazy = lazy
    end

    def optional?
      @optional
    end

    def lazy?
      @lazy
    end
  end
end
