require 'timecop'
RSpec.describe SettingsReader::VaultResolver::Cache do
  subject(:cache) { described_class.new }
  let(:address) { SettingsReader::VaultResolver::Address.new('vault://secret/key#attribute') }
  let(:secret) { instance_double(Vault::Secret, lease_duration: nil) }
  let(:entry) { SettingsReader::VaultResolver::Entry.new(address, secret) }

  describe '.retrieve' do
    subject(:result) { cache.retrieve(address) }
    context 'when static entry cached' do
      before { cache.save(entry) }

      it 'returns entry' do
        is_expected.to eq(entry)
      end

      it 'returns entry in far future' do
        Timecop.freeze do
          Timecop.travel 6000
          is_expected.to eq(entry)
        end
      end
    end

    context 'when dynamic entry cached' do
      let(:secret) { instance_double(Vault::Secret, lease_duration: 300) }

      before { cache.save(entry) }

      it 'returns entry when not expired' do
        Timecop.freeze do
          Timecop.travel 250
          is_expected.to eq(entry)
        end
      end

      it 'returns nil after expiration' do
        Timecop.freeze do
          Timecop.travel 350
          is_expected.to eq(nil)
        end
      end
    end

    context 'when not cached' do
      it { is_expected.to eq(nil) }
    end
  end
end
