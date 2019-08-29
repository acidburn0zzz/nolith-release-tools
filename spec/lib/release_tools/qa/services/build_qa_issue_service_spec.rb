# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Qa::Services::BuildQaIssueService do
  let(:version) { ReleaseTools::Version.new('10.8.0-rc1') }
  let(:from) { 'v10.8.0-rc1' }
  let(:to) { '10-8-stable' }
  let(:issue_project) { ReleaseTools::Project::Release::Tasks }
  let(:projects) do
    [
      ReleaseTools::Project::GitlabCe,
      ReleaseTools::Project::GitlabEe
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
    let(:qa_job) { double(web_url: 'https://qa-job-url') }

    before do
      allow(subject).to receive(:merge_requests).and_return(mrs)
      allow(subject).to receive(:gitlab_provisioner_gitlab_qa_job).and_return(qa_job)
    end

    it 'creates the correct issue' do
      expect(subject.issue).to be_a(ReleaseTools::Qa::Issue)
      expect(subject.issue.version).to eq(version)
      expect(subject.issue.project).to eq(issue_project)
      expect(subject.issue.merge_requests).to eq(mrs)
      expect(subject.issue.qa_job).to eq(qa_job)
    end

    context 'when SharedStatus.security_release? == true' do
      before do
        allow(ReleaseTools::SharedStatus)
          .to receive(:security_release?)
          .and_return(true)
      end

      it 'creates the correct security issue' do
        expect(subject.issue).to be_a(ReleaseTools::Qa::Issue)
        expect(subject.issue.version).to eq(version)
        expect(subject.issue.project).to eq(issue_project)
        expect(subject.issue.merge_requests).to eq(mrs)
        expect(subject.issue.qa_job).to eq(qa_job)
        expect(subject.issue).to be_confidential
      end
    end
  end
end
