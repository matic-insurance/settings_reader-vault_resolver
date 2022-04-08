RSpec.describe SettingsReader::VaultResolver::Engines::Abstract do
  let(:config) { SettingsReader::VaultResolver.configuration }
  let(:backend) { described_class.new(config) }
  let(:address) { SettingsReader::VaultResolver::Address.new('vault://secret/test#foo') }
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
      before do
        allow(backend).to receive(:get_secret).with(address).and_raise(Vault::VaultError, 'test')
      end

      it 'wraps exception' do
        expect { backend.get(address) }.to raise_error(SettingsReader::VaultResolver::Error, 'test')
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

    context 'when renew exception' do
      before do
        allow(secret).to receive(:renewable?).and_return(true)
        allow(backend).to receive(:renew_lease).with(entry).and_raise(Vault::VaultError, 'test')
      end

      it 'raises exception' do
        expect { backend.renew(entry) }.to raise_error(SettingsReader::VaultResolver::Error, 'test')
      end
    end
  end
end
