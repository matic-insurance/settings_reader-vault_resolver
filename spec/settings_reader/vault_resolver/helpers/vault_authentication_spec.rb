require 'settings_reader/vault_resolver/helpers/vault_authentication'

RSpec.describe SettingsReader::VaultResolver::Helpers::VaultAuthentication do
  let(:helper) { described_class.new }
  let(:resolver) { SettingsReader::VaultResolver.resolver }
  let(:dummy_secret) { entry_double }

  before do
    allow(SettingsReader::VaultResolver).to receive(:resolver).and_return(resolver)
    allow(resolver).to receive(:resolve).and_return(dummy_secret)
  end

  describe '#authenticate_via_k8s' do
    context 'with custom params' do
      it 'resolves entry' do
        helper.authenticate_via_k8s('test_role', route: 'test_route', service_token_path: '/var/token')
        params = 'role=test_role&route=test_route&service_token_path=%2Fvar%2Ftoken'
        url = "vault://auth/kubernetes/login?#{params}#client_token"
        expect(resolver).to have_received(:resolve).with(url, instance_of(String))
      end
    end

    context 'with minimal params' do
      it 'resolves entry' do
        helper.authenticate_via_k8s('test_role')
        url = 'vault://auth/kubernetes/login?role=test_role#client_token'
        expect(resolver).to have_received(:resolve).with(url, instance_of(String))
      end
    end
  end
end
