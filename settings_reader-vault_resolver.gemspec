require_relative 'lib/settings_reader/vault_resolver/version'

Gem::Specification.new do |spec|
  spec.name          = 'settings_reader-vault_resolver'
  spec.version       = SettingsReader::VaultResolver::VERSION
  spec.authors       = ['Volodymyr Mykhailyk']
  spec.email         = ['712680+volodymyr-mykhailyk@users.noreply.github.com']

  spec.summary       = 'Settings resolving using Vault'
  spec.description   = 'This gem works as a resolver for `settings_reader`. \
                        Any value with matching format will be resolved using Vault \
                        with support of dynamic secrets and lease support.'
  spec.homepage      = 'https://github.com'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage + "/changelog.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby', '~> 1.1'
  spec.add_dependency 'consul_application_settings', '~> 4.0.0-alpha'
  spec.add_dependency 'vault', '~> 0.16'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'codecov', '~> 0.4'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.66'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.32.0'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'timecop', '~> 0.9'
end
