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

  describe '.configure' do
    let(:initializer) { double(call: nil) }

    it 'yields configuration' do
      config = instance_of(SettingsReader::VaultResolver::Configuration)
      expect { |b| described_class.configure(&b) }.to yield_with_args(config)
    end

    it 'runs Vault initialization' do
      described_class.configure { |config| config.vault_initializer = initializer }
      expect(initializer).to have_received(:call).once
    end
  end

  describe '.refresher_timer_task' do
    it 'has configured lease refresher' do
      expect(described_class.refresher_timer_task).to be_instance_of(Concurrent::TimerTask)
    end

    it 'changes task on every configuration' do
      expect { described_class.configure }.to change(described_class, :refresher_timer_task)
    end
  end

  describe '.resolver' do
    context 'when configured' do
      it 'returns instance of resolver' do
        expect(described_class.resolver).to be_instance_of(SettingsReader::VaultResolver::Instance)
      end
    end

    context 'when not configured' do
      before { described_class.instance_variable_set(:@configuration, nil) }

      it 'raising error' do
        expect { described_class.resolver }.to raise_error(SettingsReader::VaultResolver::Error)
      end
    end
  end
end
