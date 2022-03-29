RSpec.describe SettingsReader::VaultResolver::Refresher do
  subject(:refresher) { described_class.new(cache, config) }

  let(:cache) { SettingsReader::VaultResolver::Cache.new }
  let(:config) { SettingsReader::VaultResolver::Configuration.new }
  let(:address) { instance_double(SettingsReader::VaultResolver::Address, full_path: 'test') }
  let(:entry) { instance_double(SettingsReader::VaultResolver::Entry, address: address, renew: true) }

  before do
    config.lease_renew_delay = 200
    cache.save(entry)
  end

  context 'with static secrets' do
    before do
      allow(entry).to receive(:leased?).and_return false
      allow(entry).to receive(:expires_in).and_return 1000
    end

    it 'does not renew entry' do
      refresher.refresh
      expect(entry).to_not have_received(:renew)
    end

    it 'returns empty list of refreshed promises' do
      expect(refresher.refresh).to eq([])
    end
  end

  context 'with dynamic secrets' do
    before do
      allow(entry).to receive(:leased?).and_return true
    end

    context 'when up for renewal' do
      before do
        allow(entry).to receive(:expires_in).and_return 190
        refresher.refresh
      end

      it 'renews entry' do
        expect(entry).to have_received(:renew)
      end

      it 'returns list of fulfilled promises' do
        expect(refresher.refresh.map(&:fulfilled?)).to eq([true])
      end

      it 'returns list of entries' do
        expect(refresher.refresh.map(&:value)).to eq([entry])
      end
    end

    context 'when not time to renew' do
      before do
        allow(entry).to receive(:expires_in).and_return 210
        refresher.refresh
      end

      it 'renews entry' do
        expect(entry).to_not have_received(:renew)
      end

      it 'returns empty list of refreshed promises' do
        expect(refresher.refresh).to eq([])
      end
    end

    context 'when error is raised' do
      before do
        allow(entry).to receive(:expires_in).and_return 190
        allow(entry).to receive(:renew).and_raise(SettingsReader::VaultResolver::Error, 'permission denied')
      end

      it 'handles error' do
        expect { refresher.refresh }.not_to raise_error
      end

      it 'returns list of rejected promises' do
        expect(refresher.refresh.map(&:fulfilled?)).to eq([false])
      end

      it 'returns list of errors' do
        expect(refresher.refresh.map(&:reason)).to match([instance_of(SettingsReader::VaultResolver::Error)])
      end
    end
  end
end
