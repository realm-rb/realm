# frozen_string_literal: true

module Realm
  class Context
    include Enumerable

    def initialize(*containers)
      @containers = containers.map { |c| Container[c] }
    end

    def [](name)
      @containers.each do |container|
        return container[name] if container.key?(name)
      end
      nil
    end

    def key?(name)
      @containers.any? { |container| container.key?(name) }
    end

    def merge(container_like)
      container_like.blank? ? self : self.class.new(container_like, *@containers)
    end

    def each(&block)
      @containers.each { |container| container.each(&block) }
    end

    # Just for testing
    def override!(container)
      @containers.prepend(container)
    end
  end
end
