RSpec.configure do |config|
  config.before(:each) do
    SettingsReader::VaultResolver.configure
  end
end
