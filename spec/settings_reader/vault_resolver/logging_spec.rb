RSpec.describe SettingsReader::VaultResolver::Logging do
  include described_class

  let(:logger) { instance_double(Logger) }

  before do
    allow(SettingsReader::VaultResolver).to receive(:logger).and_return(logger)
    allow(logger).to receive(:log).and_yield
  end

  describe '#debug' do
    it 'delegates to root logger' do
      expect { |b| debug(&b) }.to yield_with_no_args
      expect(logger).to have_received(:log).with(Logger::DEBUG)
    end

    it 'ignores errors in log messages' do
      expect { debug { raise 'eeee' } }.not_to raise_error
    end

    it 'specifies prefix to message' do
      allow(logger).to receive(:debug) do |*_args, &block|
        expect(block.call).to eq('[VaultResolver] test')
      end
      debug { 'test' }
    end
  end

  describe '#info' do
    it 'delegates to root logger' do
      expect { |b| info(&b) }.to yield_with_no_args
      expect(logger).to have_received(:log).with(Logger::INFO)
    end

    it 'ignores errors in log messages' do
      expect { info { raise 'eeee' } }.not_to raise_error
    end

    it 'specifies prefix to message' do
      allow(logger).to receive(:info) do |*_args, &block|
        expect(block.call).to eq('[VaultResolver] test')
      end
      info { 'test' }
    end
  end

  describe '#warn' do
    it 'delegates to root logger' do
      expect { |b| warn(&b) }.to yield_with_no_args
      expect(logger).to have_received(:log).with(Logger::WARN)
    end

    it 'ignores errors in log messages' do
      expect { warn { raise 'eeee' } }.not_to raise_error
    end

    it 'specifies prefix to message' do
      allow(logger).to receive(:warn) do |*_args, &block|
        expect(block.call).to eq('[VaultResolver] test')
      end
      warn { 'test' }
    end
  end

  describe '#error' do
    it 'delegates to root logger' do
      expect { |b| error(&b) }.to yield_with_no_args
      expect(logger).to have_received(:log).with(Logger::ERROR)
    end

    it 'ignores errors in log messages' do
      expect { error { raise 'eeee' } }.not_to raise_error
    end

    it 'specifies prefix to message' do
      allow(logger).to receive(:error) do |*_args, &block|
        expect(block.call).to eq('[VaultResolver] test')
      end
      error { 'test' }
    end
  end
end
