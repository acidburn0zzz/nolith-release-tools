require 'spec_helper'

require 'qa/issue'
require 'version'

describe Qa::Issue do
  let(:version) { Version.new('10.8.0-rc1') }
  let(:project) { Project::GitlabCe }
  let(:mr1) do
    double(
      "title" => "Resolve \"Import/Export (import) is broken due to the addition of a CI table\"",
      "author" => double("username" => "author"),
      "assignee" => double("username" => "assignee"),
      "labels" => [
        "Platform",
        "bug",
        "import",
        "project export",
        "regression"
      ],
      "sha" => "4f04aeec80bbfcb025e321693e6ca99b01244bb4",
      "merge_commit_sha" => "0065c449ff95cf6e0643bab17ed236c23207b537",
      "web_url" => "https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18745",
      "merged_by" => double("username" => "merger")
    )
  end

  let(:merge_requests) { [mr1] }

  let(:args) do
    {
      version: version,
      project: project,
      merge_requests: merge_requests
    }
  end

  it_behaves_like 'issuable #create', :create_issue
  it_behaves_like 'issuable #update', :update_issue
  it_behaves_like 'issuable #remote_issuable', :find_issue

  subject { described_class.new(args) }

  describe '#title' do
    it "returns the correct issue title" do
      expect(subject.title).to eq '10.8.0-rc1 QA Issue'
    end
  end

  describe '#description' do
    context 'for a new issue' do
      before do
        expect(subject).to receive(:remote_issuable).and_return(nil)
        @content = subject.description
      end

      it "includes the header item" do
        expect(@content).to include("# Release Candidate QA Task")
      end

      it "includes the current release version" do
        expect(@content).to include("## Merge Requests tested in RC 10.8.0-rc1")
      end

      it "includes the Team label title" do
        expect(@content).to include('### Platform')
      end

      it "includes the MR information" do
        expect(@content).to include('Import/Export (import) is broken due to the addition of a CI table')
        expect(@content).to include('gitlab-org/gitlab-ce!18745')
      end

      it "includes the MR author" do
        expect(@content).to include("@author")
      end

      it "includes the qa task for version" do
        expect(@content).to include("## Automated QA for 10.8.0-rc1")
      end
    end

    context 'for an existing issue' do
      let(:previous_revision) { 'Previous Revision' }
      let(:remote_issuable) do
        double(description: previous_revision)
      end

      before do
        expect(subject).to receive(:remote_issuable).exactly(1).times.and_return(remote_issuable)
        @content = subject.description
      end

      it "includes previous revision" do
        expect(@content).to include("Previous Revision")
      end
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      expect(subject.labels).to eq 'QA task'
    end
  end

  describe '#add_comment' do
    let(:comment_body) { "comment body" }
    let(:remote_issue_iid) { 1234 }
    let(:remote_issuable) { double(iid: remote_issue_iid) }

    before do
      expect(subject).to receive(:comment_body).and_return(comment_body)
      expect(subject).to receive(:remote_issuable).and_return(remote_issuable)
    end

    it "calls the api to create a comment" do
      expect(GitlabClient).to receive(:create_issue_note).with(project, issue: remote_issuable, body: comment_body)

      subject.add_comment
    end
  end

  describe '#comment_body' do
    it 'has the correct content' do
      expect(subject.comment_body).to eq("New QA items for: @author")
    end
  end
end
