RSpec.describe SettingsReader::VaultResolver::Engines::Aws, :vault do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:backend) { described_class.new(config) }

  describe '#retrieves?' do
    subject(:retrieves) { backend.retrieves?(address) }

    context 'with aws secret' do
      let(:address) { address_for('vault://aws/creds/app-user#username') }

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
    context 'iam user' do
      let(:address) { 'vault://aws/creds/app-user#access_key' }

      it 'returns secret' do
        expect(get_value_from(address)).not_to be_nil
      end

      it 'always retrieves fresh value' do
        expect(get_value_from(address)).not_to eq(get_value_from(address))
      end

      it 'returns configured lease' do
        entry = get_entry_from(address)
        expect(entry).to be_renewable
        expect(entry).to be_leased
        expect(entry.expires_in).to be_within(60).of(5)
      end
    end

    context 'iam role' do
      let(:address) { 'vault://aws/creds/app-role#security_token' }

      it 'returns secret' do
        expect(get_value_from(address)).not_to be_nil
      end

      it 'always retrieves fresh value' do
        expect(get_value_from(address)).not_to eq(get_value_from(address))
      end

      it 'returns configured STS lease' do
        entry = get_entry_from(address)
        expect(entry).not_to be_renewable
        expect(entry).to be_leased
        expect(entry.expires_in).to be_within(1).of(900)
      end
    end

    context 'static credentials' do
      let(:address) { 'vault://aws/static-creds/app-static-user#access_key' }

      it 'returns secret' do
        expect(get_value_from(address)).not_to be_nil
      end

      it 'retrieves save value' do
        expect(get_value_from(address)).to eq(get_value_from(address))
      end

      it 'returns correct lease' do
        entry = get_entry_from(address)
        expect(entry).not_to be_renewable
        expect(entry).not_to be_leased
      end
    end

    it 'returns nil for missing path' do
      expect(get_value_from('vault://aws/creds/app-missing#access_key')).to eq(nil)
    end

    it 'returns nil for missing attribute' do
      expect(get_value_from('vault://aws/creds/app-user#missing')).to eq(nil)
    end

    it 'raising error for permission problems' do
      error = SettingsReader::VaultResolver::Error
      expect { get_value_from('vault://aws/creds/unreachable#access_key') }.to raise_error(error)
    end

    it 'raising error for connection problems', :vault_connection_error do
      error = SettingsReader::VaultResolver::Error
      expect { get_value_from('vault://aws/creds/app-user#foo') }.to raise_error(error)
    end

    protected

    def get_value_from(path)
      address = address_for(path)
      entry = backend.get(address)
      entry&.value_for(address.attribute)
    end

    def get_entry_from(path)
      address = address_for(path)
      backend.get(address)
    end
  end

  describe '#renew' do
    context 'iam user' do
      let(:entry) { backend.get(address_for('vault://aws/creds/app-user#access_key')) }

      it 'renews secret' do
        expect { backend.renew(entry) }.to change(entry, :secret)
      end

      it 'maintains secret data' do
        expect { backend.renew(entry) }.not_to(change { entry.value_for('secret_key') })
      end
    end

    context 'iam role' do
      let(:entry) { backend.get(address_for('vault://aws/creds/app-role#access_key')) }

      it 'does not renews secret' do
        expect { backend.renew(entry) }.not_to change(entry, :secret)
      end

      it 'maintains secret data' do
        expect { backend.renew(entry) }.not_to(change { entry.value_for('secret_key') })
      end
    end
  end
end
