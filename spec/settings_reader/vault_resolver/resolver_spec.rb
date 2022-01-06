RSpec.describe SettingsReader::VaultResolver::Resolver, :vault do
  subject(:resolver) { described_class.new }
  let(:path) { 'app/secret' }

  describe '#resolvable?' do
    it 'returns true when starts with vault://' do
      expect(resolver.resolvable?('vault://applications/web/secret', path)).to be_truthy
    end

    it 'returns false for nil' do
      expect(resolver.resolvable?(nil, path)).to be_falsey
    end

    it 'returns false for other strings' do
      expect(resolver.resolvable?('vault:TEST_URL', path)).to be_falsey
    end

    it 'returns false for int' do
      expect(resolver.resolvable?(1, path)).to be_falsey
    end
  end

  describe '#resolve' do
    it 'returns value from vault' do
      set_vault_value('secret/test/app_secret?value', 'super_secret')
      expect(resolver.resolve('vault://secret/test/app_secret?value', path)).to eq('super_secret')
    end

    it 'returns nil when env missing' do
      expect(resolver.resolve('vault://secret/missing?value', path)).to eq(nil)
    end
  end
end
