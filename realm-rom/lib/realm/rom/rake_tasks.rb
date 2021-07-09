# frozen_string_literal: true

require 'rake'

module Realm
  module ROM
    module RakeTasks
      # rubocop:disable Metrics/AbcSize, Metrics/BlockLength, Metrics/MethodLength
      def self.setup(engine_name, engine_root: Rails.root.join('engines', engine_name.to_s),
                     db_url: ENV['DATABASE_URL'])
        return unless db_url

        options = { search_path: engine_name.to_s, migrator: { path: "#{engine_root}/db/migrate" } }
        config = ::ROM::Configuration.new(:sql, db_url, options)
        gateway = config.gateways[:default]

        Rake.application.in_namespace(:db) do
          Rake::Task.define_task(:init_schema) do
            gateway.run "CREATE SCHEMA IF NOT EXISTS \"#{engine_name}\""
            puts "<= #{engine_name}:db:init_schema executed"
          end

          Rake::Task.define_task(:drop_schema) do
            gateway.run "DROP SCHEMA \"#{engine_name}\" CASCADE"
            puts "<= #{engine_name}:db:drop_schema executed"
          end

          Rake.application.last_description = 'Perform migration reset (full erase and migration up)'
          Rake::Task.define_task(:reset) do
            gateway.run_migrations(target: 0)
            gateway.run_migrations
            puts "<= #{engine_name}:db:reset executed"
          end

          Rake.application.last_description = 'Migrate the database (options [version_number])]'
          Rake::Task.define_task(:migrate, %i[version]) do |_, args|
            version = args[:version]

            if version.nil?
              gateway.run_migrations
              puts "<= #{engine_name}:db:migrate executed"
            else
              gateway.run_migrations(target: version.to_i)
              puts "<= #{engine_name}:db:migrate version=[#{version}] executed"
            end
          end

          Rake.application.last_description = 'Perform migration down (removes all tables)'
          Rake::Task.define_task(:clean) do
            gateway.run_migrations(target: 0)
            puts "<= #{engine_name}:db:clean executed"
          end

          Rake.application.last_description = 'Create a migration (parameters: NAME, VERSION)'
          Rake::Task.define_task(:create_migration, %i[name version]) do |_, args|
            name, version = args.values_at(:name, :version)

            if name.nil?
              puts "No NAME specified. Example usage:
                `rake #{engine_name}:db:create_migration[create_users]`"
              exit
            end

            path = gateway.migrator.create_file(*[name, version].compact)
            puts "<= migration file created #{path}"
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/BlockLength, Metrics/MethodLength
    end
  end
end
