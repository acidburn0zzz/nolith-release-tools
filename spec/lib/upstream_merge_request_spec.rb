require 'spec_helper'

require 'upstream_merge_request'

describe UpstreamMergeRequest do
  around do |example|
    Timecop.freeze(2017, 11, 15) do
      example.run
    end
  end

  describe '.project' do
    it { expect(described_class.project).to eq Project::GitlabEe }
  end

  describe '.labels' do
    it { expect(described_class.labels).to eq 'CE upstream' }
  end

  describe '.open_mrs' do
    before do
      expect(GitlabClient).to receive(:merge_requests)
        .with(described_class.project, labels: described_class.labels, state: 'opened')
        .and_return(merge_requests)
    end

    context 'when no open upstream MR exists' do
      let(:merge_requests) { [] }

      it { expect(described_class.open_mrs).to be_empty }
    end

    context 'when an open upstream MR exists' do
      let(:merge_requests) { [double(target_branch: 'master')] }

      context 'and the target branch is master' do
        it { expect(described_class.open_mrs).to eq(merge_requests) }
      end

      context 'and the target_branch is not master' do
        let(:merge_requests) { [double(target_branch: '9-5-stable')] }

        it { expect(described_class.open_mrs).to be_empty }
      end
    end
  end

  describe '#project' do
    it { expect(subject.project).to eq described_class.project }
  end

  describe '#labels' do
    it { expect(subject.labels).to eq described_class.labels }
  end

  describe '#title' do
    it 'generates a relevant title' do
      expect(subject.title).to eq 'CE upstream - Wednesday'
    end
  end

  describe '#labels' do
    it { expect(subject.labels).to eq described_class.labels }
  end

  describe '#source_branch' do
    it 'generates a relavant source branch name' do
      expect(subject.source_branch).to eq 'ce-to-ee-2017-11-15'
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
        expect(subject.description).to eq('**Congrats, no conflicts!** :tada:')
      end
    end

    context 'conflicts is not empty' do
      before do
        subject.conflicts = [
          { path: 'foo/bar.rb', user: 'John Doe', conflict_type: 'UU' },
          { path: 'bar/baz.rb', user: 'Rémy Coutable', conflict_type: 'AA' }
        ]
      end

      it 'returns a description with checklist items for conflicting files' do
        expect(subject.description).to eq <<~CONTENT
          Files to resolve:

          - [ ] `John Doe` Please resolve [(UU) `foo/bar.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/foo/bar.rb)
          - [ ] `@rymai` Please resolve [(AA) `bar/baz.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/ce-to-ee-123/bar/baz.rb)

          Try to resolve one file per commit, and then push (no force-push!) to the `ce-to-ee-123` branch.

          Thanks in advance! :heart:

          Note: This merge request was created by an automated script.
          Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!
        CONTENT
      end

      context 'when mentioning people' do
        before do
          subject.mention_people = true
        end

        it 'does not wrap usernames in backticks' do
          expect(subject.description).to include('@rymai')
          expect(subject.description).not_to include('`@rymai`')
        end
      end
    end
  end
end
