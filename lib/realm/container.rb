# frozen_string_literal: true

require 'dry-container'

module Realm
  class Container
    include Dry::Container::Mixin

    def self.[](object)
      object.is_a?(Container) ? object : Container.new(object)
    end

    def initialize(hash = {})
      register_all(hash)
    end

    def register_all(hash)
      hash.each_pair do |key, value|
        register(key, value)
      end
    end
  end
end
