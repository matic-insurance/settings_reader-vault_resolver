RSpec.describe 'SettingsReader integration', :vault do
  let(:settings_path) { File.expand_path('../fixtures/settings.yml', __dir__) }
  let(:settings) do
    SettingsReader.load do |config|
      config.backends = [SettingsReader::Backends::YamlFile.new(settings_path)]
      config.resolvers << SettingsReader::VaultResolver.resolver
    end
  end

  context 'when reading yml settings' do
    it 'returns value' do
      puts settings_path
      expect(settings.get('app/name')).to eq('SettingsReader::VaultResolver')
    end
  end

  context 'when reading resolvable value' do
    context 'when value is static secret' do
      it 'returns value' do
        expect(settings.get('resources/static_secret/existing')).to eq('a')
      end

      it 'returns nil for unknown attribute' do
        expect(settings.get('resources/static_secret/missing_attribute')).to eq(nil)
      end

      it 'returns nil for unknown secret' do
        expect(settings.get('resources/static_secret/unknown_secret')).to eq(nil)
      end
    end

    context 'when value is dynamic secret' do
      it 'returns value' do
        expect(settings.get('resources/dynamic_secret/user')).to start_with('v-token-app-user')
      end

      it 'caches value' do
        expect(settings.get('resources/dynamic_secret/pass')).to eq(settings.get('resources/dynamic_secret/pass'))
      end
    end
  end
end
