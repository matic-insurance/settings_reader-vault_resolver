RSpec.describe SettingsReader::VaultResolver::Entry do
  subject(:entry) { described_class.new(address, secret) }

  let(:secret) { instance_double(Vault::Secret) }
  let(:address) { SettingsReader::VaultResolver::Address.new('vault://secret/key#attribute') }

  before { entry }

  describe '.leased?' do
    subject { entry.leased? }

    context 'when secret has lease and duration' do
      before do
        allow(secret).to receive(:lease_id).and_return('123')
        allow(secret).to receive(:lease_duration).and_return(360)
      end

      it { is_expected.to be_truthy }
    end

    context 'when secret has no lease id and duration' do
      before do
        allow(secret).to receive(:lease_id).and_return(nil)
        allow(secret).to receive(:lease_duration).and_return(0)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '.expired?' do
    subject { entry.expired? }

    context 'when secret is not leased' do
      before do
        allow(secret).to receive(:lease_id).and_return(nil)
      end

      it { is_expected.to be_falsey }
    end

    context 'when secret is leased' do
      before do
        allow(secret).to receive(:lease_id).and_return('123')
        allow(secret).to receive(:lease_duration).and_return(60)
      end

      it 'return false when lease not expired' do
        Timecop.freeze do
          Timecop.travel 59
          is_expected.to be_falsey
        end
      end

      it 'return true when lease expired' do
        Timecop.freeze do
          Timecop.travel 61
          is_expected.to be_truthy
        end
      end
    end
  end

  describe '.expires_in' do
    subject { entry.expires_in }

    context 'when secret is not leased' do
      before do
        allow(secret).to receive(:lease_id).and_return(nil)
      end

      it { is_expected.to eq(108_000) }
    end

    context 'when secret is leased' do
      before do
        allow(secret).to receive(:lease_id).and_return('123')
        allow(secret).to receive(:lease_duration).and_return(60)
      end

      it 'return time to expiration' do
        Timecop.freeze do
          Timecop.travel 30
          is_expected.to be_within(1).of(30)
        end
      end
    end
  end

  describe '.renew' do
    let(:renewed_secret) { instance_double(Vault::Secret, lease_id: '234', lease_duration: 60) }

    before do
      allow(Vault.sys).to receive(:renew).with('123').and_return(renewed_secret)
      allow(secret).to receive(:lease_duration).and_return(30)
    end

    context 'when not leased' do
      before do
        allow(secret).to receive(:lease_id).and_return(nil)
      end

      it 'does not renew secret' do
        entry.renew
        expect(Vault.sys).to_not have_received(:renew)
      end

      it 'secret remains unchanged' do
        expect { entry.renew }.to_not change(entry, :secret)
      end

      it 'expiration is updated' do
        expect { entry.renew }.to_not change(entry, :expires_in)
      end
    end

    context 'when leased' do
      before do
        allow(secret).to receive(:lease_id).and_return('123')
      end

      it 'does not renew secret' do
        entry.renew
        expect(Vault.sys).to have_received(:renew).with('123')
      end

      it 'secret is updated' do
        expect { entry.renew }.to change(entry, :secret).to(renewed_secret)
      end

      it 'expiration is updated' do
        expect { entry.renew }.to change(entry, :expires_in).to(be_within(1).of(60))
      end
    end
  end

  describe 'renew integration', :vault do
    let(:address) { 'vault://database/creds/app-user#username' }
    let(:secret) { Vault.logical.read('database/creds/app-user') }

    it 'updates secret' do
      expect { entry.renew }.to change(entry, :secret)
    end
  end
end
