require 'settings_reader/vault_resolver/helpers/vault_authentication'

RSpec.describe 'SettingsReader::VaultResolver failover' do
  include Helpers::VaultHelpers

  let(:resolver) { SettingsReader::VaultResolver.resolver }

  context 'when using external authentication' do
    before do
      SettingsReader::VaultResolver.configure do |config|
        config.vault_initializer = -> { retrieve_new_vault_token }
      end
      static_secret
    end

    context 'when vault token revoked' do
      context 'when able to authenticate again' do
        it 're-authenticates' do
          expect do
            Vault.token = 'invalid'
            static_secret
          end.to change(Vault, :token)
        end

        it 'returns secret after re-authentication' do
          Vault.auth_token.revoke_self
          expect(static_secret).to eq('a')
        end
      end

      context 'when authentication not working' do
        before do
          Vault.token = 'invalid'
          allow(Vault.auth_token).to receive(:create).and_raise(vault_auth_error)
        end

        it 'raising error' do
          expect { static_secret }.to raise_error(SettingsReader::VaultResolver::Error)
        end
      end
    end
  end

  context 'when using auth backend' do
    before do
      allow(Vault.auth).to receive(:kubernetes).and_wrap_original do
        retrieve_new_vault_token
      end
      SettingsReader::VaultResolver.configure do |config|
        config.vault_initializer = lambda do
          SettingsReader::VaultResolver::Helpers::VaultAuthentication.new.authenticate_via_k8s('test')
        end
      end
      static_secret
    end

    context 'when able to authenticate again' do
      it 're-authenticates' do
        expect do
          invalidate_vault_authentication
          static_secret
        end.to change(Vault, :token)
      end

      it 'returns secret after re-authentication' do
        invalidate_vault_authentication
        expect(static_secret).to eq('a')
      end
    end

    context 'when authentication not working' do
      before do
        invalidate_vault_authentication
        allow(Vault.auth_token).to receive(:create).and_raise(vault_auth_error)
      end

      it 'raising error' do
        expect { static_secret }.to raise_error(SettingsReader::VaultResolver::Error)
      end
    end
  end

  protected

  def static_secret
    SettingsReader::VaultResolver.cache.clear_all
    resolver.resolve('vault://secret/pre-configured#foo', 'secret/path')
  end
end
