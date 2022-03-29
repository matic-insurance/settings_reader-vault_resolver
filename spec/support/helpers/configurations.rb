RSpec.configure do |config|
  config.before(:each) do
    SettingsReader::VaultResolver.configure do |conf|
      conf.logger = Logger.new($stdout, level: Logger::FATAL)
    end
  end
end
