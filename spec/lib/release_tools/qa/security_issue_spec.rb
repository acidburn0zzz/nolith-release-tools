require 'spec_helper'

describe ReleaseTools::Qa::SecurityIssue do
  let(:version) { ReleaseTools::Version.new('10.8.0-rc1') }
  let(:project) { ReleaseTools::Project::GitlabCe }
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
      "web_url" => "https://dev.gitlab.org/gitlabhq/gitlabhq/merge_requests/612",
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

  describe '#confidential?' do
    it 'is always confidential' do
      expect(subject).to be_confidential
    end
  end

  describe '#title' do
    it "returns the correct issue title" do
      expect(subject.title).to eq '10.8.0-rc1 Security QA Issue'
    end
  end

  describe '#description' do
    context 'for a new issue' do
      before do
        expect(subject).to receive(:remote_issuable).and_return(nil)
        @content = subject.description
      end

      it "includes the MR information" do
        expect(@content).to include('Import/Export (import) is broken due to the addition of a CI table')
        expect(@content).to include('https://dev.gitlab.org/gitlabhq/gitlabhq/merge_requests/612')
      end

      it "includes some security-specific headers" do
        expect(@content).to include('### Prepare the environments for testing the security fixes')
        expect(@content).to include('### Coordinate the Manual QA validation of the release')
      end
    end
  end

  describe '#labels' do
    it 'returns a list of labels' do
      expect(subject.labels).to eq 'QA task,security'
    end
  end
end
