RSpec.describe SettingsReader::VaultResolver::Engines::Auth, :vault do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:engine) { described_class.new(config) }

  describe '#retrieves?' do
    subject(:retrieves) { engine.retrieves?(address) }

    context 'with auth secret' do
      let(:address) { address_for('vault://auth/kubernetes/login#token?role=test') }

      it { is_expected.to eq(true) }
    end

    context 'with database secret' do
      let(:address) { address_for('vault://database/creds/app-user#username') }

      it { is_expected.to eq(false) }
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
    let(:secret_auth) { instance_double(Vault::SecretAuth, client_token: 'client_token_data') }
    let(:secret) { instance_double(Vault::Secret, auth: secret_auth) }

    context 'when k8s auth' do
      before do
        allow(Vault.auth).to receive(:kubernetes).and_return(secret)
      end

      context 'with minimal params' do
        let(:address) { 'vault://auth/kubernetes/login?role=test_role#client_token' }

        it 'returns token' do
          value = get_value_from(address)
          expect(value.secret).to eq(secret_auth)
        end

        it 'passing right arguments' do
          get_value_from(address)
          expect(Vault.auth).to have_received(:kubernetes).with('test_role', route: nil, service_token_path: nil)
        end
      end

      context 'with all params' do
        let(:address) { 'vault://auth/kubernetes/login?role=role&route=route&service_token_path=path#client_token' }

        it 'returns token' do
          value = get_value_from(address)
          expect(value.secret).to eq(secret_auth)
        end

        it 'passing right arguments' do
          get_value_from(address)
          expect(Vault.auth).to have_received(:kubernetes).with('role', route: 'route', service_token_path: 'path')
        end
      end
    end

    context 'when other auth auth' do
      it 'returns token' do
        address = 'vault://auth/approle/login#client_token'
        message = "Unsupported auth backed for #{address}"
        expect { get_value_from(address) }.to raise_error(SettingsReader::VaultResolver::Error, message)
      end
    end

    protected

    def get_value_from(address)
      engine.get(address_for(address))
    end
  end

  describe '#renew' do
    let(:entry) { build_entry_for('vault://auth/kubernetes/login#client_token', old_secret) }
    let(:secret_auth) { instance_double(Vault::SecretAuth, renewable?: true, lease_duration: 120) }
    let(:new_secret) { instance_double(Vault::Secret, auth: secret_auth) }
    let(:old_secret) { instance_double(Vault::SecretAuth, renewable?: true, lease_duration: 120) }

    before do
      allow(Vault.client.auth_token).to receive(:renew_self).and_return(new_secret)
    end

    it 'updates secret' do
      expect { engine.renew(entry) }.to change(entry, :secret).to(secret_auth)
    end

    it 'updates expiration' do
      expect { engine.renew(entry) }.to change(entry, :expires_in).to be_within(1).of(120)
    end
  end
end
