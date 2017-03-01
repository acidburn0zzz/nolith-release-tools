require 'spec_helper'
require 'gitlab_dev_client'

describe GitlabDevClient do
  describe '.create_repo_variable' do
    it 'creates a CI variable with the repository name in it', vcr: { cassette_name: 'dev_ci/repository_variables' } do
      result = described_class.create_repo_variable('super_secret_repo')

      expect(result.key).to eq('PACKAGECLOUD_REPO')
      expect(result.value).to eq('super_secret_repo')
    end

    after do
      described_class.remove_repo_variable
    end
  end

  describe '.fetch_repo_variable' do
    before do
      described_class.create_repo_variable('super_secret_repo')
    end

    it 'fetches a CI variable stored previously and returns its value', vcr: { cassette_name: 'dev_ci/repository_variables' } do
      expect(described_class.fetch_repo_variable).to eq('super_secret_repo')
    end

    after do
      described_class.remove_repo_variable
    end
  end

  describe '.remove_repo_variable' do
    before do
      described_class.create_repo_variable('super_secret_repo')
    end

    it 'fetches a CI variable stored previously and returns its value', vcr: { cassette_name: 'dev_ci/remove_repository_variables' } do
      expect(described_class.remove_repo_variable).to eq(true)
      expect(described_class.fetch_repo_variable).to eq(false)
    end
  end
end
