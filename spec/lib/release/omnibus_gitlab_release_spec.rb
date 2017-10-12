require 'spec_helper'
require 'release/omnibus_gitlab_release'

describe Release::OmnibusGitlabRelease, :silence_stdout do
  describe 'security repo' do
    let(:omnibus_release) { described_class.new('1.0') }
    let(:error_message) do
      "Existing security release defined in CI: security-20170101T0000Z (cannot start new one: security-20170102T0100Z)."
    end

    before do
      allow_any_instance_of(PackagecloudClient).to receive(:create_secret_repository).and_return(true)
      allow(GitlabDevClient).to receive(:create_repo_variable).and_return(true)
      allow(GitlabDevClient).to receive(:fetch_repo_variable).and_return("security-#{Time.utc(2017, 1, 1).strftime('%Y%m%dT%H%MZ')}")
    end

    it 'raises error if the repo variable is after the grace period' do
      Timecop.freeze(Time.utc(2017, 1, 2, 1)) do
        expect { omnibus_release.send(:prepare_security_release) }
          .to raise_error(Release::OmnibusGitlabRelease::SecurityReleaseInProgressError, error_message)
      end
    end

    it 'does not raise an error if the repo variable is before the grace period' do
      Timecop.freeze(Time.utc(2017, 1, 1, 12)) do
        expect { omnibus_release.send(:prepare_security_release) }
          .not_to raise_error
      end
    end
  end
end
