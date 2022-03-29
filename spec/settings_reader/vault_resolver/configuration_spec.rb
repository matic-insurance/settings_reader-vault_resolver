RSpec.describe SettingsReader::VaultResolver::Configuration do
  let(:config) { described_class.new }
  let(:cache) { instance_double(SettingsReader::VaultResolver::Cache) }

  describe '#setup_lease_refresher' do
    let(:task) { instance_double(Concurrent::TimerTask, execute: true, add_observer: true) }

    before { allow(Concurrent::TimerTask).to receive(:new).and_return(task) }

    context 'when executing task' do
      before do
        allow(Concurrent::TimerTask).to receive(:new).and_yield.and_return(task)
        allow(cache).to receive(:entries).and_return []
      end

      it 'does it without exceptions' do
        expect { config.setup_lease_refresher(cache) }.not_to raise_error
      end
    end

    context 'without previous task' do
      it 'instantiate task with correct params' do
        config.setup_lease_refresher(cache)
        expect(Concurrent::TimerTask).to have_received(:new).with(execution_interval: config.lease_refresh_interval)
      end

      it 'returns task' do
        expect(config.setup_lease_refresher(cache)).to eq(task)
      end

      it 'starts task' do
        config.setup_lease_refresher(cache)
        expect(task).to have_received(:execute)
      end

      it 'adds observer' do
        config.setup_lease_refresher(cache)
        expect(task).to have_received(:add_observer).with(instance_of(SettingsReader::VaultResolver::RefresherObserver))
      end
    end

    context 'with previous task' do
      let(:previous_task) { instance_double(Concurrent::TimerTask, shutdown: true) }

      it 'instantiate task with correct params' do
        config.setup_lease_refresher(cache, previous_task)
        expect(Concurrent::TimerTask).to have_received(:new).with(execution_interval: config.lease_refresh_interval)
      end

      it 'returns task' do
        expect(config.setup_lease_refresher(cache, previous_task)).to eq(task)
      end

      it 'starts task' do
        config.setup_lease_refresher(cache, previous_task)
        expect(task).to have_received(:execute)
      end

      it 'adds observer' do
        config.setup_lease_refresher(cache, previous_task)
        expect(task).to have_received(:add_observer).with(instance_of(SettingsReader::VaultResolver::RefresherObserver))
      end

      it 'shuts down old task' do
        config.setup_lease_refresher(cache, previous_task)
        expect(previous_task).to have_received(:shutdown)
      end
    end
  end
end
