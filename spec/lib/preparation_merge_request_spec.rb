require 'spec_helper'

require 'preparation_merge_request'
require 'version'

describe PreparationMergeRequest do
  it_behaves_like 'issuable #initialize'
  it_behaves_like 'issuable #create', :create_merge_request

  let(:merge_request) { described_class.new(version: Version.new('9.4.1')) }
  let(:ee_merge_request) { described_class.new(version: Version.new('9.4.1-ee')) }
  let(:rc_merge_request) { described_class.new(version: Version.new('9.4.0-rc2')) }
  let(:ee_rc_merge_request) { described_class.new(version: Version.new('9.4.0-rc2-ee')) }

  let(:subject) { merge_request }

  it 'has an informative WIP title', :aggregate_failures do
    expect(merge_request.title).to eq 'WIP: Prepare 9.4.1 release'
    expect(ee_merge_request.title).to eq 'WIP: Prepare 9.4.1-ee release'
    expect(rc_merge_request.title).to eq 'WIP: Prepare 9.4.0-rc2 release'
    expect(ee_rc_merge_request.title).to eq 'WIP: Prepare 9.4.0-rc2-ee release'
  end

  describe '#labels' do
    it 'are set correctly on the MR' do
      expect(merge_request.labels).to eq 'Delivery'
    end
  end

  it 'determines milestone from version' do
    expect(merge_request.milestone).to eq '9.4'
  end

  describe '#preparation_branch_name' do
    it 'appends the stable branch with patch number' do
      expect(merge_request.preparation_branch_name).to eq '9-4-stable-patch-1'
      expect(ee_merge_request.preparation_branch_name).to eq '9-4-stable-ee-patch-1'
    end

    context 'release candidate' do
      it 'appends the stable branch with rc number' do
        expect(rc_merge_request.preparation_branch_name).to eq '9-4-stable-prepare-rc2'
        expect(ee_rc_merge_request.preparation_branch_name).to eq '9-4-stable-ee-prepare-rc2'
      end
    end
  end

  it 'sets source_branch to the new branch' do
    expect(merge_request.source_branch).to eq merge_request.preparation_branch_name
  end

  it 'sets target_branch to the stable branch' do
    expect(merge_request.target_branch).to eq '9-4-stable'
  end

  describe '#patch_or_rc_version' do
    it 'returns the short version number' do
      aggregate_failures do
        expect(merge_request.patch_or_rc_version).to eq '9.4.1'
        expect(ee_merge_request.patch_or_rc_version).to eq '9.4.1-ee'
        expect(rc_merge_request.patch_or_rc_version).to eq 'RC2'
        expect(ee_rc_merge_request.patch_or_rc_version).to eq 'RC2'
      end
    end
  end

  context 'EE' do
    it 'returns "ee" for #repo_ce_or_ee' do
      expect(ee_merge_request.repo_ce_or_ee).to eq 'ee'
      expect(ee_rc_merge_request.repo_ce_or_ee).to eq 'ee'
    end

    it 'sets project to EE' do
      expect(ee_merge_request.project).to eq Project::GitlabEe
    end
  end

  describe '#description' do
    before do
      allow_any_instance_of(MonthlyIssue).to receive(:url).and_return('https://dummy-issue.url')
      allow_any_instance_of(PatchIssue).to receive(:url).and_return('https://dummy-issue.url')
    end

    it 'includes a link to the release issue' do
      expect(merge_request.description).to include 'https://dummy-issue.url'
    end

    it 'includes pick-into-stable URL for finding MRs' do
      expect(merge_request.description).to include "https://gitlab.com/gitlab-org/gitlab-ce/merge_requests?label_name%5B%5D=Pick+into+9.4&scope=all&state=merged"
      expect(ee_merge_request.description).to include "gitlab-ee/merge_requests?label_name%5B%5D=Pick+into+9.4"
    end

    it 'explains that the MR branch will merge into stable' do
      aggregate_failures do
        expect(merge_request.description).to include "merging `9-4-stable-patch-1` into `9-4-stable`"
        expect(ee_merge_request.description).to include "merging `9-4-stable-ee-patch-1` into `9-4-stable-ee`"
        expect(rc_merge_request.description).to include "merging `9-4-stable-prepare-rc2` into `9-4-stable`"
        expect(ee_rc_merge_request.description).to include "merging `9-4-stable-ee-prepare-rc2` into `9-4-stable-ee`"
      end
    end
  end

  describe '#create_branch!', vcr: { cassette_name: 'branches/create_preparation' } do
    it 'creates the preparation branch in the correct project' do
      merge_request = described_class.new(version: Version.new('9.4.99'))

      branch = merge_request.create_branch!

      expect(branch.name).to eq '9-4-stable-patch-99'
    end

    it "doesn't throw error when the branch exists", vcr: { cassette_name: 'branches/create_existing' } do
      expect { merge_request.create_branch! }.not_to raise_error
    end
  end
end
