RSpec.describe SettingsReader::VaultResolver::Refresher do
  subject(:refresher) { described_class.new(cache) }

  let(:cache) { SettingsReader::VaultResolver::Cache.new }
  let(:address) { instance_double(SettingsReader::VaultResolver::Address, full_path: 'test') }
  let(:entry) { instance_double(SettingsReader::VaultResolver::Entry, address: address, renew: true) }

  before { cache.save(entry) }

  context 'with static secrets' do
    before do
      allow(entry).to receive(:leased?).and_return false
      refresher.refresh
    end

    it 'does not renew entry' do
      expect(entry).to_not have_received(:renew)
    end
  end

  context 'with dynamic secrets' do
    before do
      allow(entry).to receive(:leased?).and_return true
    end

    context 'when up for renewal' do
      before do
        allow(entry).to receive(:expires_in).and_return 90
        refresher.refresh
      end

      it 'renews entry' do
        expect(entry).to have_received(:renew)
      end
    end

    context 'when not time to renew' do
      before do
        allow(entry).to receive(:expires_in).and_return 150
        refresher.refresh
      end

      it 'renews entry' do
        expect(entry).to_not have_received(:renew)
      end
    end
  end
end
