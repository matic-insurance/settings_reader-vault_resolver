module Helpers
  module GemShortcuts
    def address_for(path)
      SettingsReader::VaultResolver::Address.new(path)
    end
  end
end

RSpec.configure do |config|
  config.include(Helpers::GemShortcuts)
end