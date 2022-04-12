RSpec.describe SettingsReader::VaultResolver::Engines::Abstract do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:backend) { described_class.new(config) }
  let(:address) { address_for('vault://secret/test#foo') }
  let(:secret) { instance_double(Vault::Secret) }

  describe '#retrieves?' do
    it 'raising error' do
      expect { backend.retrieves?(address) }.to raise_error(NotImplementedError)
    end
  end

  describe '#get' do
    context 'when secret returned' do
      before do
        allow(backend).to receive(:get_secret).with(address).and_return(secret)
      end

      it 'returns entry with secret' do
        entry = backend.get(address)
        expect(entry.address).to eq(address)
        expect(entry.secret).to eq(secret)
      end
    end

    context 'when secret nil' do
      before do
        allow(backend).to receive(:get_secret).with(address).and_return(nil)
      end

      it 'returns nil' do
        expect(backend.get(address)).to eq(nil)
      end
    end

    context 'when vault exception raised' do
      context 'when connection exception happened less then retries' do
        before do
          error = Vault::HTTPConnectionError.new('test_address', SocketError.new('test'))
          allow(backend).to receive(:get_secret, &sporadic_exceptions(secret, error, result_after: 1))
        end

        it 'returns entry with secret' do
          entry = backend.get(address)
          expect(entry.address).to eq(address)
          expect(entry.secret).to eq(secret)
        end
      end

      context 'when connection exception happened more then retries' do
        before do
          error = Vault::HTTPConnectionError.new('test_address', SocketError.new('test'))
          allow(backend).to receive(:get_secret, &sporadic_exceptions(secret, error, result_after: 3))
        end

        it 'raises exception' do
          message = /The Vault server at `test_address' is not currently/
          expect { backend.get(address) }.to raise_error(SettingsReader::VaultResolver::Error, message)
        end
      end
    end
  end

  describe '#renew' do
    let(:renewed_secret) { instance_double(Vault::Secret, renewable?: true, lease_duration: 60) }
    let(:entry) { SettingsReader::VaultResolver::Entry.new(address, secret) }

    before do
      allow(backend).to receive(:renew_lease).with(entry).and_return(renewed_secret)
      allow(secret).to receive(:lease_duration).and_return(30)
    end

    context 'when not leased' do
      before do
        allow(secret).to receive(:renewable?).and_return(false)
      end

      it 'secret remains unchanged' do
        expect { backend.renew(entry) }.to_not change(entry, :secret)
      end

      it 'expiration is not updated' do
        expect { backend.renew(entry) }.to_not change(entry, :expires_in)
      end
    end

    context 'when leased' do
      before do
        allow(secret).to receive(:renewable?).and_return(true)
      end

      it 'secret is updated' do
        expect { backend.renew(entry) }.to change(entry, :secret).to(renewed_secret)
      end

      it 'expiration is updated' do
        expect { backend.renew(entry) }.to change(entry, :expires_in).to(be_within(1).of(60))
      end
    end

    context 'when renew connection exception' do
      before do
        @call_count = 0
        allow(secret).to receive(:renewable?).and_return(true)
      end

      context 'when connection exception happened less then retries' do
        before do
          error = Vault::HTTPConnectionError.new('test_address', SocketError.new('test'))
          allow(backend).to receive(:renew_lease, &sporadic_exceptions(renewed_secret, error, result_after: 3))
        end

        it 'secret is updated' do
          expect { backend.renew(entry) }.to change(entry, :secret).to(renewed_secret)
        end
      end

      context 'when connection exception happened more then retries' do
        before do
          error = Vault::HTTPConnectionError.new('test_address', SocketError.new('test'))
          allow(backend).to receive(:renew_lease, &sporadic_exceptions(renewed_secret, error, result_after: 5))
        end

        it 'raises exception' do
          message = /The Vault server at `test_address' is not currently/
          expect { backend.renew(entry) }.to raise_error(SettingsReader::VaultResolver::Error, message)
        end
      end

      context 'when server/client exception happened once' do
        before do
          error = Vault::HTTPError.new('address', double(:response, code: 503), %w[error1 error2])
          allow(backend).to receive(:renew_lease, &sporadic_exceptions(renewed_secret, error, result_after: 3))
        end

        it 'raises exception' do
          message = /The Vault server at `address' responded with a 503/
          expect { backend.renew(entry) }.to raise_error(SettingsReader::VaultResolver::Error, message)
        end
      end
    end
  end

  protected

  def sporadic_exceptions(result, error, result_after: 5)
    call_count = 0
    proc do
      raise error unless (call_count += 1) > result_after

      result
    end
  end
end
