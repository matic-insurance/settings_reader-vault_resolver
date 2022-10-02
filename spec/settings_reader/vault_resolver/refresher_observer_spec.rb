RSpec.describe SettingsReader::VaultResolver::RefresherObserver do
  let(:observer) { described_class.new(config) }
  let(:config) { SettingsReader::VaultResolver::Configuration.new }
  let(:success_listener) { ->(_result) {} }
  let(:error_listener) { ->(_result) {} }

  before do
    allow(success_listener).to receive(:call).and_call_original
    allow(error_listener).to receive(:call).and_call_original

    config.lease_renew_success_listener = success_listener
    config.lease_renew_error_listener = error_listener
  end

  context 'when no leases refreshed' do
    it 'does not execute listeners' do
      observer.update(Time.now, [], nil)
      expect(success_listener).not_to have_received(:call)
      expect(error_listener).not_to have_received(:call)
    end
  end

  context 'when one lease refreshed' do
    let(:entry) { entry_double }

    it 'executes success listener' do
      observer.update(Time.now, [Concurrent::Promise.fulfill(entry)], nil)
      expect(success_listener).to have_received(:call).with(entry)
      expect(error_listener).not_to have_received(:call)
    end
  end

  context 'when one lease failed' do
    let(:error) { SettingsReader::VaultResolver::Error.new('test') }

    it 'executes error listener' do
      observer.update(Time.now, [Concurrent::Promise.reject(error)], nil)
      expect(success_listener).not_to have_received(:call)
      expect(error_listener).to have_received(:call).with(error)
    end
  end

  context 'when multiple promises' do
    let(:entry) { entry_double }
    let(:error) { SettingsReader::VaultResolver::Error.new('test') }

    it 'executes both listeners' do
      observer.update(Time.now, [Concurrent::Promise.reject(error), Concurrent::Promise.fulfill(entry)], nil)
      expect(success_listener).to have_received(:call).with(entry)
      expect(error_listener).to have_received(:call).with(error)
    end
  end

  context 'when task failed' do
    let(:error) { SettingsReader::VaultResolver::Error.new('test') }

    it 'does not execute listeners' do
      observer.update(Time.now, nil, error)
      expect(success_listener).not_to have_received(:call)
      expect(error_listener).to have_received(:call).with(error)
    end
  end
end
