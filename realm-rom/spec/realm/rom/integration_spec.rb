# frozen_string_literal: true

require 'pg'

%w[app lib].each do |dir|
  Dir[File.join(__dir__, 'sample_app', dir, '**', '*.rb')].sort.each do |f|
    require f
  end
end

app_root = File.expand_path('sample_app', __dir__)

RSpec.describe 'Integration of ROM plugin with realm core' do
  let(:realm) do
    Realm.setup(
      SampleApp,
      plugins: :rom,
      root_path: app_root,
      persistence_gateway: { type: :rom, url: ENV['DATABASE_URL'] },
    ).runtime
  end

  before(:all) do
    Realm::ROM::RakeTasks.setup(:sample_app, engine_root: app_root)
  end

  before do
    Rake::Task['db:init_schema'].invoke
    Rake::Task['db:reset'].invoke
  end

  it 'works for happy path' do
    realm.run('review.create', text: 'Awesome')
    reviews = realm.query('review.all')
    expect(reviews.size).to eq 1
    expect(reviews[0].text).to eq 'Awesome'
  end
end
