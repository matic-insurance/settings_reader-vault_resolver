require 'timecop'
RSpec.describe SettingsReader::VaultResolver::Cache do
  subject(:cache) { described_class.new }
  let(:address) { SettingsReader::VaultResolver::Address.new('vault://secret/key#attribute') }
  let(:secret) { instance_double(Vault::Secret, renewable?: nil) }
  let(:entry) { SettingsReader::VaultResolver::Entry.new(address, secret) }

  describe '.retrieve' do
    subject(:result) { cache.retrieve(address) }
    context 'when static entry cached' do
      before { cache.save(entry) }

      it 'returns entry' do
        is_expected.to eq(entry)
      end

      it 'returns entry for another attribute' do
        address = SettingsReader::VaultResolver::Address.new('vault://secret/key#another')
        expect(cache.retrieve(address)).to eq(entry)
      end

      it 'returns entry in far future' do
        Timecop.freeze do
          Timecop.travel 6000
          is_expected.to eq(entry)
        end
      end
    end

    context 'when dynamic entry cached' do
      let(:secret) { instance_double(Vault::Secret, lease_duration: 300, renewable?: true) }

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
        address = SettingsReader::VaultResolver::Address.new('vault://secret/another#attribute')
        expect(cache.retrieve(address)).to eq(nil)
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
