require 'spec_helper'

require 'upstream_merge_request'

describe UpstreamMergeRequest do
  around do |example|
    Timecop.freeze('2017-11-15 18:12 UTC') do
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
      expect(subject.title).to eq 'CE upstream - 2017-11-15 18:12 UTC'
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
      allow(CommitAuthor).to receive(:new).with('John Doe', team: an_instance_of(Team)).and_return(double(to_gitlab: 'John Doe'))
      allow(CommitAuthor).to receive(:new).with('Rémy Coutable', team: an_instance_of(Team)).and_return(double(to_gitlab: '@rymai'))
      allow(CI).to receive(:current_job_url).and_return('http://job.url')
      allow(Team).to receive(:new).with(included_core_members: described_class::INCLUDED_CORE_MEMBERS).and_call_original.once
    end

    context 'conflicts is empty' do
      it 'returns a nice description' do
        subject.conflicts = []

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

          [More detailed instructions](https://docs.gitlab.com/ee/development/automatic_ce_ee_merge.html#what-to-do-if-you-are-pinged-in-a-ce-upstream-merge-request-to-resolve-a-conflict)

          Thanks in advance! :heart:

          @rymai After you resolved the conflicts,
          please assign to the next person. If you're the last one to resolve
          the conflicts, please push this to be merged.

          Note: This merge request was [created by an automated script](http://job.url).
          Please report any issue at https://gitlab.com/gitlab-org/release-tools/issues!

          /assign @rymai
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

  describe '#responsible_gitlab_username' do
    subject do
      merge_request.__send__(:responsible_gitlab_username)
    end

    let(:merge_request) { described_class.new }

    before do
      allow(merge_request)
        .to receive(:most_mentioned_gitlab_username)
        .and_return(most_mentioned)
    end

    context 'when there is a most mentioned gitlab username' do
      let(:most_mentioned) { '@gitlab' }

      it 'picks the most mentioned one' do
        expect(subject).to eq(most_mentioned)
      end
    end

    context 'when there is not a most mentioned gitlab username' do
      let(:most_mentioned) { nil }

      it 'picks one from the CE to EE team' do
        expect(subject).to be_in(
          described_class::CE_TO_EE_TEAM.map { |name| "@#{name}" }
        )
      end
    end
  end

  describe '#most_mentioned_gitlab_username' do
    subject do
      merge_request.__send__(:most_mentioned_gitlab_username)
    end

    let(:merge_request) { described_class.new }
    let(:authors) { %w[Apple Pineapple @gitlab Orange] }

    before do
      allow(merge_request)
        .to receive_message_chain(:authors, :values)
        .and_return(authors)
    end

    it 'only picks users starting with @' do
      expect(subject).to eq('@gitlab')
    end
  end

  describe '#sample_most_duplicated' do
    using RSpec::Parameterized::TableSyntax

    subject do
      described_class.new.__send__(:sample_most_duplicated, array)
    end

    context 'when the array contains one most duplicated element' do
      where(:picked, :array) do
        1    | [1, 3, 5, 7, 9, 1, 3, 1]
        'a'  | %w[this is a pen and that's a mouse]
        true | [false, true, false, true, true]
      end

      with_them do
        it { is_expected.to eq(picked) }
      end
    end

    context 'when the array contains more than one most duplicated element' do
      where(:possible_picks, :array) do
        [1, 3]        | [1, 3, 5, 7, 9, 1, 3]
        %w[is a]      | %w[this is a pen and that is a mouse]
        [true, false] | [false, true, false, true, nil]
      end

      with_them do
        it { is_expected.to be_in(possible_picks) }
      end
    end
  end
end
