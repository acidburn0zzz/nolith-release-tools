require 'spec_helper'

require 'qa/services/build_qa_issue_service'

describe Qa::Services::BuildQaIssueService do
  let(:version) { Version.new('10.8.0-rc1') }
  let(:from) { 'v10.8.0-rc1' }
  let(:to) { '10-8-stable' }
  let(:issue_project) { Project::Release::Tasks }
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

      it 'returns the issue' do
        expect(subject.execute).to eq(issue_double)
      end
    end

    context 'remote issue does not exist' do
      let(:remote_issuable) { false }

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
      expect(subject.issue).to be_a(Qa::Issue)
      expect(subject.issue.version).to eq(version)
      expect(subject.issue.project).to eq(issue_project)
      expect(subject.issue.merge_requests).to eq(mrs)
    end

    context 'when SharedStatus.security_release? == true' do
      before do
        allow(SharedStatus).to receive(:security_release?).and_return(true)
      end

      it 'creates the correct security issue' do
        expect(subject.issue).to be_a(Qa::SecurityIssue)
        expect(subject.issue.version).to eq(version)
        expect(subject.issue.project).to eq(issue_project)
        expect(subject.issue.merge_requests).to eq(mrs)
        expect(subject.issue).to be_confidential
      end
    end
  end

  describe '#changesets' do
    it 'creates a new changeset for each project' do
      expect(Qa::ProjectChangeset).to receive(:new)
        .with(project: Project::GitlabCe, from: 'v10.8.0-rc1', to: '10-8-stable', default_client: GitlabClient)
      expect(Qa::ProjectChangeset).to receive(:new)
        .with(project: Project::GitlabEe, from: 'v10.8.0-rc1-ee', to: '10-8-stable-ee', default_client: GitlabClient)

      expect(subject.changesets.size).to eq(2)
    end

    context 'when SharedStatus.security_release? == true' do
      before do
        allow(SharedStatus).to receive(:security_release?).and_return(true)
      end

      it 'creates a new changeset for each project using GitlabDevClient' do
        expect(Qa::ProjectChangeset).to receive(:new)
          .once
          .with(project: Project::GitlabCe, from: 'v10.8.0-rc1', to: '10-8-stable', default_client: GitlabDevClient)
        expect(Qa::ProjectChangeset).to receive(:new)
          .once
          .with(project: Project::GitlabEe, from: 'v10.8.0-rc1-ee', to: '10-8-stable-ee', default_client: GitlabDevClient)

        expect(subject.changesets.size).to eq(2)
      end
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
