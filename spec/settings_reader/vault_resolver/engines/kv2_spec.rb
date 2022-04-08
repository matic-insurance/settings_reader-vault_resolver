RSpec.describe SettingsReader::VaultResolver::Engines::KV2, :vault do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:backend) { described_class.new(config) }

  describe '#retrieves?' do
    subject(:retrieves) { backend.retrieves?(address) }

    context 'with kv address' do
      let(:address) { address_for('vault://secret/pre-configured#foo') }

      it { is_expected.to eq(true) }
    end

    context 'with database secret' do
      let(:address) { address_for('vault://database/creds/app-user#username') }

      it { is_expected.to eq(false) }
    end

    context 'with other address' do
      let(:address) { address_for('vault://another_mount/pre-configured#foo') }

      it { is_expected.to eq(false) }
    end
  end

  describe '#get' do
    it 'returns value set in vault' do
      set_vault_value('test/app_secret', value: 'super_secret')
      expect(get_value_from('vault://secret/test/app_secret#value')).to eq('super_secret')
    end

    it 'always retrieves fresh value' do
      address = 'vault://secret/test/app_secret#value'
      set_vault_value('test/app_secret', value: 'super_secret')
      get_value_from(address)
      set_vault_value('test/app_secret', value: 'another_secret')
      expect(get_value_from(address)).to eq('another_secret')
    end

    it 'returns preconfigured value' do
      expect(get_value_from('vault://secret/pre-configured#foo')).to eq('a')
    end

    it 'returns nil for missing path' do
      expect(get_value_from('vault://secret/test/unknown#test')).to eq(nil)
    end

    it 'returns nil for missing attribute' do
      expect(get_value_from('vault://secret/test/app_secret#missing')).to eq(nil)
    end

    it 'raising error for permission problems' do
      error = SettingsReader::VaultResolver::Error
      expect { get_value_from('vault://secret/unreachable/secret#missing') }.to raise_error(error)
    end

    it 'raising error for connection problems', :vault_connection_error do
      error = SettingsReader::VaultResolver::Error
      expect { get_value_from('vault://secret/pre-configured#foo') }.to raise_error(error)
    end

    protected

    def get_value_from(path)
      address = SettingsReader::VaultResolver::Address.new(path)
      entry = backend.get(address)
      entry&.value_for(address.attribute)
    end
  end

  describe '#renew' do
    let(:entry) { backend.get(address_for('vault://secret/pre-configured#foo')) }

    it 'not updates secret' do
      expect { backend.renew(entry) }.not_to change(entry, :secret)
    end

    it 'not updates expiration' do
      expect { backend.renew(entry) }.not_to change(entry, :expires_in)
    end
  end
end
