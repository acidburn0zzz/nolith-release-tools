require 'spec_helper'

require 'upstream_merge_request'

describe UpstreamMergeRequest do
  around do |example|
    Timecop.freeze do
      example.run
    end
  end

  describe '.open_mrs' do
    context 'when no open upstream MR exists' do
      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: described_class::LABELS, state: 'opened')
          .and_return([])
      end

      it { expect(described_class.open_mrs).to be_empty }
    end

    context 'when an open upstream MR exists' do
      let(:mr) { double(target_branch: 'master') }

      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: described_class::LABELS, state: 'opened')
          .and_return([mr])
      end

      it { expect(described_class.open_mrs).to eq([mr]) }
    end

    context 'when an open MR exists but the target_branch is not master' do
      let(:mr) { double(target_branch: '9-5-stable') }

      before do
        allow(GitlabClient).to receive(:merge_requests)
          .with(Project::GitlabEe, labels: described_class::LABELS, state: 'opened')
          .and_return([mr])
      end

      it { expect(described_class.open_mrs).to be_empty }
    end
  end

  describe '#project' do
    it { expect(subject.project).to eq Project::GitlabEe }
  end

  describe '#title' do
    it 'generates a relavant title' do
      Timecop.freeze do
        expect(subject.title).to eq "CE upstream - #{Date.today.strftime('%A')}"
      end
    end
  end

  describe '#labels' do
    it { expect(subject.labels).to eq described_class::LABELS }
  end

  describe '#source_branch' do
    it 'generates a relavant source branch name' do
      Timecop.freeze do
        expect(subject.source_branch).to eq "ce-to-ee-#{Date.today.iso8601}"
      end
    end
  end

  describe '#description' do
    subject { described_class.new(source_branch: 'ce-to-ee-123') }

    before do
      allow(CommitAuthor).to receive(:new).with('John Doe').and_return(double(to_gitlab: 'John Doe'))
      allow(CommitAuthor).to receive(:new).with('Rémy Coutable').and_return(double(to_gitlab: '@rymai'))
    end

    context 'conflicts is empty' do
      it 'returns a nice description' do
        expect(subject.description).to eq('Congrats, no conflicts!')
      end
    end

    context 'conflicts is not empty' do
      let(:conflicts) do
        [
          { path: 'foo/bar.rb', user: 'John Doe', conflict_type: 'UU' },
          { path: 'bar/baz.rb', user: 'Rémy Coutable', conflict_type: 'AA' }
        ]
      end

      before do
        subject.conflicts = conflicts
      end

      it 'returns a description with checklist items for conflicting files' do
        expect(subject.description).to eq <<~CONTENT
          Files to resolve:

          - [ ] `John Doe` Please resolve [(UU) `foo/bar.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/foo/bar.rb)
          - [ ] `@rymai` Please resolve [(AA) `bar/baz.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/bar/baz.rb)

          Try to resolve one file per commit, and then push (no force-push!) to the `ce-to-ee-123` branch.

          Thanks in advance! ❤️

          Note: This merge request was created by an automated script.
          Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!
        CONTENT
      end

      context 'when mentioning people' do
        before do
          subject.mention_people = true
        end

        it 'returns a description with checklist items for conflicting files with usernames wrapped in backticks' do
          expect(subject.description).to eq <<~CONTENT
            Files to resolve:

            - [ ] John Doe Please resolve [(UU) `foo/bar.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/foo/bar.rb)
            - [ ] @rymai Please resolve [(AA) `bar/baz.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/bar/baz.rb)

            Try to resolve one file per commit, and then push (no force-push!) to the `ce-to-ee-123` branch.

            Thanks in advance! ❤️

            Note: This merge request was created by an automated script.
            Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!
          CONTENT
        end
      end
    end
  end
end
