RSpec.describe SettingsReader::VaultResolver::Entry do
  subject(:entry) { described_class.new(address, secret) }

  let(:secret) { instance_double(Vault::Secret) }
  let(:address) { address_for('vault://secret/key#attribute') }

  before { entry }

  describe '.leased?' do
    subject { entry.leased? }

    context 'when secret is renewable' do
      before do
        allow(secret).to receive(:renewable?).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when secret has no lease id and duration' do
      before do
        allow(secret).to receive(:renewable?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '.expired?' do
    subject { entry.expired? }

    context 'when secret is not renewable' do
      before do
        allow(secret).to receive(:renewable?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when secret is leased' do
      before do
        allow(secret).to receive(:renewable?).and_return(true)
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
        allow(secret).to receive(:renewable?).and_return(false)
      end

      it { is_expected.to eq(108_000) }
    end

    context 'when secret is leased' do
      before do
        allow(secret).to receive(:renewable?).and_return(true)
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
end
