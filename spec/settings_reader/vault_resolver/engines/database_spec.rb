RSpec.describe SettingsReader::VaultResolver::Engines::Database, :vault do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:backend) { described_class.new(config) }

  describe '#retrieves?' do
    subject(:retrieves) { backend.retrieves?(address) }

    context 'with database secret' do
      let(:address) { address_for('vault://database/creds/app-user#username') }

      it { is_expected.to eq(true) }
    end

    context 'with kv address' do
      let(:address) { address_for('vault://secret/pre-configured#foo') }

      it { is_expected.to eq(false) }
    end

    context 'with other address' do
      let(:address) { address_for('vault://another_mount/pre-configured#foo') }

      it { is_expected.to eq(false) }
    end
  end

  describe '#get' do
    it 'returns secret' do
      value = get_value_from('vault://database/creds/app-user#username')
      expect(value).to start_with('v-token-app-user-')
    end

    it 'always retrieves fresh value' do
      address = 'vault://database/creds/app-user#username'
      expect(get_value_from(address)).not_to eq(get_value_from(address))
    end

    it 'returns nil for missing path' do
      expect(get_value_from('vault://database/creds/unknown-db#username')).to eq(nil)
    end

    it 'returns nil for missing attribute' do
      expect(get_value_from('vault://database/creds/app-user#missing')).to eq(nil)
    end

    it 'raising error for permission problems' do
      error = SettingsReader::VaultResolver::Error
      expect { get_value_from('vault://database/creds/unreachable#username') }.to raise_error(error)
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
    let(:entry) { backend.get(address_for('vault://database/creds/app-user#username')) }

    it 'updates secret' do
      expect { backend.renew(entry) }.to change(entry, :secret)
    end

    it 'updates expiration' do
      expect { backend.renew(entry) }.to change(entry, :expires_in).to be_within(1).of(60)
    end
  end
end
