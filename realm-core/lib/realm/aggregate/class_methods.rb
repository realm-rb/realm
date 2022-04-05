# frozen_string_literal: true

module Realm
  class Aggregate
    module ClassMethods
      attr_reader :root_class, :root_name

      def find(id, expected_version = nil, on_older: :catchup, on_newer: :return)
        root = root_class.find_by(aggregate_id: id)
        return new(root) unless expected_version

        if root.aggregate_version < expected_version
          case on_older
          when :fail
            raise Stale, expected_version, root.aggregate_version
          when :catchup
            # TODO: update projection
            return find(id, expected_version, on_older: :fail, on_newer: on_newer)
          else
            raise "Not supported on_older option value: #{on_older}"
          end
        elsif root.aggregate_version > expected_version
          case on_newer
          when :fail
            raise Outran, expected_version, root.aggregate_version
          when :return
            # do nothing
          else
            raise "Not supported on_newer option value: #{on_newer}"
          end
        end

        new(root)
      end

      def apply(event)
        find(event.stream_id, event.position).apply(event) if applicable?(event)
      end

      def discover(force: false)
        return if instance_variable_defined?(:@discovery_ran) && !force # run only once

        constants(false).each do |const_sym|
          const = const_get(const_sym)
          next unless const.is_a?(Module)

          if const < CommandHandler
            define_method(const_sym.to_s.underscore) do |*args, **kwargs|
              outbox = const.(self.root, *args, **kwargs)
              outbox.each { |event| apply(event) }
              nil
            end
          elsif const < EventHandler
            const.handled_event_classes.each do |klass|
              event_handlers[klass] << const
            end
          end
        end

        event_handlers.freeze
        @discovery_ran = true
      end

      def event_handlers
        @event_handlers ||= Hash.new { |h, k| h.frozen? ? [] : h[k] = [] }
      end

      def applicable?(event)
        handled_event_classes.include?(event.class)
      end

      def handled_event_classes
        @handled_event_classes ||= event_handlers.keys.uniq.freeze
      end

      def inherited(subclass)
        subclass.extend(SubclassMethods)
        super
      end

      private

      def root(root_class, as: nil)
        @root_class = root_class
        @root_name = as || root_class.name.underscore.to_sym
      end

      def command_methods(*methods)
        @command_methods = methods
      end

      def on(*event_classes, &block)
        handler = Aggregate::EventHandler.new(&block)
        event_classes.each do |klass|
          event_handlers[klass] << handler
        end
      end
    end
  end
end
