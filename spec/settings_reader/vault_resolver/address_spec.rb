RSpec.describe SettingsReader::VaultResolver::Address do
  context 'simple path' do
    subject(:address) { described_class.new('vault://secret/key#attribute') }

    it 'has correct mount' do
      expect(address.mount).to eq('secret')
    end

    it 'has correct path' do
      expect(address.path).to eq('/key')
    end

    it 'has correct full path' do
      expect(address.full_path).to eq('secret/key')
    end

    it 'has correct attribute' do
      expect(address.attribute).to eq('attribute')
    end

    it 'has correct options' do
      expect(address.options).to eq({})
    end
  end

  context 'full path with options' do
    subject(:address) { described_class.new('vault://database/path/to/role?renew=false#username') }

    it 'has correct mount' do
      expect(address.mount).to eq('database')
    end

    it 'has correct path' do
      expect(address.path).to eq('/path/to/role')
    end

    it 'has correct full path' do
      expect(address.full_path).to eq('database/path/to/role')
    end

    it 'has correct attribute' do
      expect(address.attribute).to eq('username')
    end

    it 'has correct options' do
      expect(address.options).to eq('renew' => 'false')
    end
  end
end
