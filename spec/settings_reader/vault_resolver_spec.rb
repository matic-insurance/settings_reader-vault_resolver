RSpec.describe SettingsReader::VaultResolver do
  it "has default 0 version number" do
    expect(SettingsReader::VaultResolver::VERSION).to eq('0.0.0')
  end

  it 'has configured cache' do
    expect(described_class.cache).to be_instance_of(SettingsReader::VaultResolver::Cache)
  end

  it 'has configured lease refresher' do
    described_class.refresher_timer_task
    expect(described_class.refresher_timer_task).to be_instance_of(Concurrent::TimerTask)
  end
end
