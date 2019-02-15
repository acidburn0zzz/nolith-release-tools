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

    it 'explains that the MR branch will merge into stable', :aggregate_failures do
      expect(merge_request.description).to include "prepares `9-4-stable` for `9.4.1`."
      expect(ee_merge_request.description).to include "prepares `9-4-stable-ee` for `9.4.1-ee`."
      expect(rc_merge_request.description).to include "prepares `9-4-stable` for `9.4.0-rc2`."
      expect(ee_rc_merge_request.description).to include "prepares `9-4-stable-ee` for `9.4.0-rc2-ee`."
    end
  end

  describe '#link!' do
    it 'replaces a preparation link template' do
      remote = double(
        project_id: 1,
        iid: 1234,
        description: <<~DESC
          Foo

          {{CE_PREPARATION_MR_LINK}}
        DESC
      )

      allow(merge_request).to receive(:release_issue)
        .and_return(double(remote_issuable: remote))

      expect(merge_request).to receive(:url).and_return('gitlab.example.com')
      expect(GitlabClient).to receive(:edit_issue).with(
        1,
        1234,
        description: "Foo\n\ngitlab.example.com\n"
      )

      subject.link!
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
