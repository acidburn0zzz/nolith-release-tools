require 'spec_helper'

require 'qa/services/qa_issue_service'

describe Qa::Services::QaIssueService do
  let(:version) { Version.new('10.8.0-rc1') }
  let(:from) { 'v10.8.0-rc1' }
  let(:to) { '10-8-stable' }
  let(:issue_project) { Project::ReleaseTasks }
  let(:projects) do
    [
      Project::GitlabCe,
      Project::GitlabEe
    ]
  end

  subject do
    described_class.new(
      version: version,
      from: from,
      to: to,
      issue_project: issue_project,
      projects: projects
    )
  end

  describe '#execute' do
    let(:issue_double) do
      double("issue", version: version,
                      project: issue_project,
                      merge_requests: [],
                      remote_issuable: remote_issuable)
    end

    before do
      allow(subject).to receive(:issue).and_return(issue_double)
    end

    context 'remote issue already exists' do
      let(:remote_issuable) { true }

      before do
        expect(issue_double).to receive(:update).once
        expect(issue_double).to receive(:add_comment).once
      end

      it 'calls update and add_comment on the issue' do
        subject.execute
      end

      it 'returns the issue' do
        expect(subject.execute).to eq(issue_double)
      end
    end

    context 'remote issue does not exist' do
      let(:remote_issuable) { false }

      before do
        expect(issue_double).to receive(:create).once
      end

      it 'calls create on the issue' do
        subject.execute
      end

      it 'returns the issue' do
        expect(subject.execute).to eq(issue_double)
      end
    end
  end

  describe '#issue' do
    let(:mrs) { ["mr1"] }

    before do
      allow(subject).to receive(:merge_requests).and_return(mrs)
    end

    it 'creates the correct issue' do
      expect(subject.issue.version).to eq(version)
      expect(subject.issue.project).to eq(issue_project)
      expect(subject.issue.merge_requests).to eq(mrs)
    end
  end

  describe '#changesets' do
    it 'creates a new changeset for each project' do
      expect(Qa::ProjectChangeset).to receive(:new).exactly(1).times.with(Project::GitlabCe, 'v10.8.0-rc1', '10-8-stable')
      expect(Qa::ProjectChangeset).to receive(:new).exactly(1).times.with(Project::GitlabEe, 'v10.8.0-rc1-ee', '10-8-stable-ee')

      expect(subject.changesets.size).to eq(2)
    end
  end

  describe '#merge_requests' do
    let(:mr1) { double("mr1", id: 1, labels: []) }
    let(:mr2) { double("mr2", id: 2, labels: []) }
    let(:mr3) { double("mr3", id: 3, labels: []) }
    let(:dupe_mr) { double("dupe", id: 1, labels: []) }
    let(:changesets) do
      [
        double(merge_requests: [mr1, mr2]),
        double(merge_requests: [mr3, dupe_mr])
      ]
    end

    before do
      allow(subject).to receive(:changesets).and_return(changesets)
    end

    it 'retrieves unique merge_requests from all changesets' do
      expect(subject.merge_requests.size).to eq(3)
      expect(subject.merge_requests).not_to include(dupe_mr)
    end

    it 'excludes Release MRs' do
      mr1.labels << 'Release'

      expect(subject.merge_requests).not_to include(mr1)
    end
  end
end
