require 'timecop'
RSpec.describe SettingsReader::VaultResolver::Cache do
  subject(:cache) { described_class.new }
  let(:address) { address_for('vault://secret/key#attribute') }
  let(:secret) { vault_secret_double(renewable?: nil) }
  let(:entry) { build_entry_for(address, secret) }

  describe '.retrieve' do
    subject(:result) { cache.retrieve(address) }
    context 'when static entry cached' do
      before { cache.save(entry) }

      it 'returns entry' do
        is_expected.to eq(entry)
      end

      it 'returns entry for another attribute' do
        expect(cache.retrieve(address_for('vault://secret/key#another'))).to eq(entry)
      end

      it 'returns entry in far future' do
        Timecop.freeze do
          Timecop.travel 6000
          is_expected.to eq(entry)
        end
      end
    end

    context 'when dynamic entry cached' do
      let(:secret) { vault_secret_double(lease_duration: 300, renewable?: true) }

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

    context 'when another address is cached' do
      before { cache.save(entry) }

      it 'returns nil' do
        expect(cache.retrieve(address_for('vault://secret/another#attribute'))).to eq(nil)
      end
    end
  end

  describe '.fetch' do
    context 'when cached' do
      let(:fetch) { cache.fetch(address) { raise 'eeee' } }

      before { cache.save(entry) }

      it 'does not execute block' do
        expect { fetch }.to_not raise_error
      end

      it 'does not removes cache' do
        fetch
        expect(cache.retrieve(address)).to eq(entry)
      end

      it 'returns entry' do
        expect(fetch).to eq(entry)
      end
    end

    context 'when not cached' do
      let(:fetch) { cache.fetch(address) { entry } }

      it 'returns entry' do
        expect(fetch).to eq(entry)
      end

      it 'saves entry to cache' do
        fetch
        expect(cache.retrieve(address)).to eq(entry)
      end
    end
  end
end
