# rubocop:disable Naming/FileName
# frozen_string_literal: true

Dir[File.join(File.dirname(__FILE__), 'realm', '**', '*.rb')].sort.each do |f|
  require f
end

# rubocop:enable Naming/FileName
