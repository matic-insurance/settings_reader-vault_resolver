RSpec.describe SettingsReader::VaultResolver do
  it "has default 0 version number" do
    expect(SettingsReader::VaultResolver::VERSION).to eq('0.0.0')
  end
end
