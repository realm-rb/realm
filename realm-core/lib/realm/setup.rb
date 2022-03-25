# frozen_string_literal: true

module Realm
  class Setup
    class << self
      Realm::Config.dry_initializer.options.map(&:source).without(:plugins, :dependencies).each do |name|
        define_method(name) do |value|
          options[name] = value
        end
      end

      def plug(plugin, **plugin_options)
        options[:plugins] << { name: plugin, **plugin_options }
      end

      def unplug(plugin)
        options[:plugins].delete_if { |p| p[:name] == plugin }
      end

      def register(key, value)
        # TODO: pass options to Container#register
        options[:dependencies][key] = value
      end

      # TODO: add register_factory

      def init
        Realm.setup(options.fetch(:root_module) { module_parent }, **options)
      end

      def bind
        Realm.bind(options.fetch(:root_module) { module_parent }, **options)
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@options, @options.dup)
        super
      end

      private

      def options
        @options ||= { plugins: [], dependencies: {} }
      end
    end
  end
end
