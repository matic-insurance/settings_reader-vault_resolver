require 'settings_reader/vault_resolver/helpers/vault_authentication'

RSpec.describe SettingsReader::VaultResolver::Helpers::VaultAuthentication do
  let(:helper) { described_class.new }
  let(:auth_secret) { instance_double(Vault::SecretAuth, client_token: 'vault_client_token', renewable?: true) }
  let(:secret) { vault_secret_double(auth: auth_secret) }

  before do
    allow(Vault.auth).to receive(:kubernetes).and_return(secret)
  end

  describe '#authenticate_via_k8s' do
    context 'with custom params' do
      it 'logins via Vault authentication method' do
        helper.authenticate_via_k8s('test_role', route: 'test_route', service_token_path: '/var/token')
        params = { route: 'test_route', service_token_path: '/var/token' }
        expect(Vault.auth).to have_received(:kubernetes).with('test_role', params)
      end

      it 'returns token' do
        token = helper.authenticate_via_k8s('test_role', route: 'test_route', service_token_path: '/var/token')
        expect(token).to eq('vault_client_token')
      end
    end

    context 'with minimal params' do
      it 'resolves entry' do
        helper.authenticate_via_k8s('test_role')
        expect(Vault.auth).to have_received(:kubernetes).with('test_role', { route: nil, service_token_path: nil })
      end

      it 'returns token' do
        token = helper.authenticate_via_k8s('test_role', route: 'test_route', service_token_path: '/var/token')
        expect(token).to eq('vault_client_token')
      end
    end
  end
end
