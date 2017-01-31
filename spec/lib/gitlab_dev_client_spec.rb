require 'spec_helper'
require 'gitlab_dev_client'

describe GitlabDevClient do
  describe '.create_repo_variable' do
    it 'creates a CI variable and store informed name in it', vcr: { cassette_name: 'dev_ci/repository_variables' } do
      result = described_class.create_repo_variable('super_secret_repo')

      expect(result.key).to eq('PACKAGECLOUD_REPO')
      expect(result.value).to eq('super_secret_repo')
    end

    after { described_class.remove_repo_variable }
  end

  describe '.fetch_repo_variable' do
    before { described_class.create_repo_variable('super_secret_repo') }

    it 'fetches a CI variable stored previously and return its value', vcr: { cassette_name: 'dev_ci/repository_variables' } do
      expect(described_class.fetch_repo_variable).to eq('super_secret_repo')
    end

    after { described_class.remove_repo_variable }
  end

  describe '.remove_repo_variable' do
    before { described_class.create_repo_variable('super_secret_repo') }

    it 'fetches a CI variable stored previously and return its value', vcr: { cassette_name: 'dev_ci/remove_repository_variables' } do
      expect(described_class.remove_repo_variable).to eq(true)
      expect(described_class.fetch_repo_variable).to eq(false)
    end
  end
end
