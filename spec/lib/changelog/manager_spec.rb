require 'spec_helper'

require 'changelog/config'
require 'changelog/manager'
require 'version'

describe Changelog::Manager do
  include RuggedMatchers

  let(:fixture)    { File.expand_path('../../fixtures/repositories/changelog', __dir__) }
  let(:repository) { Rugged::Repository.new(fixture) }
  let(:config)     { Changelog::Config }

  describe 'initialize' do
    it 'accepts a path String' do
      manager = described_class.new(fixture)

      expect(manager.repository).to be_kind_of(Rugged::Repository)
    end

    it 'accepts a Rugged::Repository object' do
      manager = described_class.new(repository)

      expect(manager.repository).to eq repository
    end

    it 'raises an error for any other object' do
      expect { described_class.new(StringIO.new) }.to raise_error(RuntimeError)
    end
  end

  describe '#release', 'for CE' do
    let(:version) { Version.new('8.10.5') }

    let(:master) { repository.branches['master'] }
    let(:stable) { repository.branches[version.stable_branch] }

    before do
      reset_fixture!

      described_class.new(repository).release(version)
    end

    it 'updates the changelog file' do
      expect(master.target).to have_modified(config.ce_log)
      expect(stable.target).to have_modified(config.ce_log)
    end

    it 'removes only the changelog files picked into stable' do
      picked   = File.join(config.ce_path, 'fix-cycle-analytics-commits.yml')
      unpicked = File.join(config.ce_path, 'group-specific-lfs.yml')

      aggregate_failures do
        expect(master.target).to have_deleted(picked)
        expect(master.target).to have_blob(unpicked)

        expect(stable.target).to have_deleted(picked)
        expect(stable.target).not_to have_deleted(unpicked)
        expect(stable.target).not_to have_blob(unpicked)
      end
    end

    it 'adds a sensible commit message' do
      message = "Update #{config.ce_log} for #{version}\n\n[ci skip]"

      aggregate_failures do
        expect(master.target.message).to eq(message)
        expect(stable.target.message).to eq(message)
      end
    end
  end

  describe '#release', 'for EE' do
    let(:version) { Version.new('8.10.5-ee') }

    let(:master) { repository.branches['master'] }
    let(:stable) { repository.branches[version.stable_branch] }

    before do
      reset_fixture!

      described_class.new(repository).release(version)
    end

    it 'updates the changelog file' do
      expect(master.target).to have_modified(config.ee_log)
      expect(stable.target).to have_modified(config.ee_log)
    end

    it 'removes only the changelog files picked into stable' do
      picked   = File.join(config.ee_path, 'protect-branch-missing-param.yml')

      aggregate_failures do
        expect(master.target).to have_deleted(picked)
        expect(stable.target).to have_deleted(picked)
      end
    end

    it 'adds a sensible commit message' do
      message = "Update #{config.ee_log} for #{version}\n\n[ci skip]"

      aggregate_failures do
        expect(master.target.message).to eq(message)
        expect(stable.target.message).to eq(message)
      end
    end
  end

  def reset_fixture!
    ChangelogFixture.new.rebuild_fixture!
  end
end
