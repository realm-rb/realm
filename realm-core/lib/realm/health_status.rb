# frozen_string_literal: true

module Realm
  class HealthStatus
    CODES = %i[green yellow red].freeze
    attr_reader :code, :issues

    class << self
      def [](code, *issues)
        new(code, issues.flatten)
      end

      def from_issues(issues)
        new(issues.blank? ? :green : :red, issues)
      end

      def combine(component_map)
        code_index = component_map.values.map { |i| CODES.index(i.code) }.max
        new(CODES[code_index || 0], [], component_map)
      end
    end

    def for_component(*names)
      @component_map.dig(*names)
    end

    def to_h
      hash = { status: @code }
      hash[:issues] = @issues if @issues.present?
      hash[:components] = @component_map.transform_values(&:to_h) if @component_map.present?
      hash
    end

    private

    def initialize(code, issues = [], component_map = {})
      raise ArgumentError, "Invalid status code #{code}" unless CODES.include?(code)

      @code = code
      @issues = issues.freeze
      @component_map = component_map.freeze
    end
  end
end
