# frozen_string_literal: true

require 'pg'
require 'rake'

RSpec.describe 'Integration of ROM plugin with realm core' do
  let(:namespaced_classes) { false }
  let(:app_root) { File.expand_path(app_dir, __dir__) }
  let(:realm) do
    Realm.setup(
      root_module,
      plugins: :rom,
      root_path: app_root,
      namespaced_classes: namespaced_classes,
      persistence_gateway: {
        type: :rom,
        url: ENV['DATABASE_URL'],
        db_namespace: root_module.to_s.underscore,
      },
    ).runtime
  end

  shared_examples 'check setup' do
    it 'works for happy path' do
      %w[app lib].each do |dir|
        Dir[File.join(__dir__, app_dir, dir, '**', '*.rb')].sort.each do |f|
          require f
        end
      end

      Rake.application.in_namespace(app_dir) do
        Realm::ROM::RakeTasks.setup(app_dir, engine_root: app_root)
      end
      Rake::Task["#{app_dir}:db:init_schema"].invoke
      Rake::Task["#{app_dir}:db:reset"].invoke

      realm.run('review.create', text: 'Awesome')
      reviews = realm.query('review.all')
      expect(reviews.size).to eq 1
      expect(reviews[0].text).to eq 'Awesome'
    end
  end

  context 'for not namespaced app (typical for Rails)' do
    let(:root_module) { SampleApp }
    let(:app_dir) { 'sample_app' }

    include_examples 'check setup'
  end

  context 'for namespaced app (typical for Rails engines)' do
    let(:root_module) { SampleAppNamespaced }
    let(:app_dir) { 'sample_app_namespaced' }
    let(:namespaced_classes) { true }

    include_examples 'check setup'
  end
end
