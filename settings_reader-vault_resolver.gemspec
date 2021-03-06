require_relative 'lib/settings_reader/vault_resolver/version'

Gem::Specification.new do |spec|
  spec.name          = 'settings_reader-vault_resolver'
  spec.version       = SettingsReader::VaultResolver::VERSION
  spec.authors       = ['Volodymyr Mykhailyk']
  spec.email         = ['volodymyr.mykhailyk@gmail.com']

  spec.summary       = 'Settings Reader plugin to resolve values using in Hashicorp Vault'
  spec.description   = 'This gem works as a resolver for `settings_reader` gem. \
                        Any value with matching format will be resolved using Vault \
                        with support of dynamic secrets and lease renewal.'
  spec.homepage      = 'https://github.com/matic-insurance/settings_reader-vault_resolver'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|local)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby', '~> 1.1'
  spec.add_dependency 'settings_reader', '~> 0.1'
  spec.add_dependency 'vault', '~> 0.16'
end
