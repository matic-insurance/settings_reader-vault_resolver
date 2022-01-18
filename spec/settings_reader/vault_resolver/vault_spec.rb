RSpec.describe SettingsReader::Resolver::Vault, :vault do
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
    context 'k/v' do
      it 'returns value set in vault' do
        set_vault_value('test/app_secret', value: 'super_secret')
        expect(resolver.resolve('vault://secret/test/app_secret#value', path)).to eq('super_secret')
      end

      it 'caching retrieved value' do
        address = 'vault://secret/test/app_secret#value'
        set_vault_value('test/app_secret', value: 'super_secret')
        resolver.resolve(address, path)
        set_vault_value('test/app_secret', value: 'another_secret')
        expect(resolver.resolve(address, path)).to eq('super_secret')
      end

      it 'returns preconfigured value' do
        expect(resolver.resolve('vault://secret/pre-configured#foo', path)).to eq('a')
      end

      it 'returns nil for missing path' do
        expect(resolver.resolve('vault://secret/unknown#test', path)).to eq(nil)
      end

      it 'returns nil for missing attribute' do
        expect(resolver.resolve('vault://secret/test/app_secret#missing', path)).to eq(nil)
      end
    end

    context 'dynamic db secret' do
      it 'returns user name' do
        value = resolver.resolve('vault://database/creds/app-user#username', path)
        expect(value).to start_with('v-token-app-user-')
      end

      it 'caching retrieved value' do
        address = 'vault://database/creds/app-user#username'
        expect(resolver.resolve(address, path)).to eq(resolver.resolve(address, path))
      end

      it 'returns password' do
        value = resolver.resolve('vault://database/creds/app-user#password', path)
        expect(value).not_to be(nil)
      end

      it 'returns nil for missing path' do
        expect(resolver.resolve('vault://database/creds/unknown-db#username', path)).to eq(nil)
      end

      it 'returns nil for missing attribute' do
        expect(resolver.resolve('vault://database/creds/app-user#missing', path)).to eq(nil)
      end
    end

    it 'returns nil when env missing' do
      expect(resolver.resolve('vault://secret/missing#value', path)).to eq(nil)
    end
  end
end
