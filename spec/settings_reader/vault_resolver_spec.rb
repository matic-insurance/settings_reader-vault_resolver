RSpec.describe SettingsReader::VaultResolver do
  it 'has default 0 version number' do
    expect(SettingsReader::VaultResolver::VERSION).to eq('0.0.0')
  end

  describe '.cache' do
    it 'has configured cache' do
      expect(described_class.cache).to be_instance_of(SettingsReader::VaultResolver::Cache)
    end

    it 'configures cache only once' do
      expect(described_class.cache).to eq(described_class.cache)
    end
  end

  describe '.refresher_timer_task' do
    it 'has configured lease refresher' do
      expect(described_class.refresher_timer_task).to be_instance_of(Concurrent::TimerTask)
    end

    it 'does not change task on second setup' do
      expect { described_class.setup_lease_refresher }.not_to change(described_class, :refresher_timer_task)
    end
  end

  it 'returns instance of resolver' do
    expect(described_class.resolver).to be_instance_of(SettingsReader::VaultResolver::Instance)
  end
end
