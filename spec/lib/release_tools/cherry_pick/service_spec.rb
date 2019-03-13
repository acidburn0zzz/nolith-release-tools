require 'spec_helper'

describe ReleaseTools::CherryPick::Service do
  let(:version) { ReleaseTools::Version.new('11.4.0-rc8') }

  subject { described_class.new(ReleaseTools::Project::GitlabCe, version) }

  describe 'initialize' do
    it 'validates version argument' do
      expect { described_class.new(double, double(valid?: false)) }
        .to raise_error(RuntimeError, /Invalid version provided/)
    end

    it 'validates preparation MR' do
      stub_const('ReleaseTools::PreparationMergeRequest', spy(exists?: false))

      expect { described_class.new(double, version) }
        .to raise_error(RuntimeError, /Preparation merge request not found/)
    end
  end

  describe '#execute', vcr: { cassette_name: 'cherry_pick/with_prep_mr' } do
    context 'with no pickable MRs' do
      it 'does nothing' do
        expect(subject).to receive(:pickable_mrs).and_return([])

        expect(subject.execute).to eq([])
      end
    end

    context 'with pickable MRs' do
      def stub_picking
        # If the `merge_commit_sha` contains `failure`, we raise an error to
        # simulate a failed pick; otherwise return true
        allow(ReleaseTools::GitlabClient).to receive(:cherry_pick) do |_, keywords|
          if keywords[:ref].start_with?('failure')
            raise Gitlab::Error::BadRequest.new(double.as_null_object)
          else
            true
          end
        end
      end

      let(:target) { '11-4-stable-prepare-rc8' }
      let(:notifier) { spy }
      let(:picks) do
        Gitlab::PaginatedResponse.new(
          [
            double(iid: 1, project_id: 13_083, merge_commit_sha: 'success-a'),
            double(iid: 2, project_id: 13_083, merge_commit_sha: 'success-b'),

            double(iid: 3, project_id: 13_083, merge_commit_sha: 'failure-a'),
            double(iid: 4, project_id: 13_083, merge_commit_sha: 'failure-b'),
            double(iid: 5, project_id: 13_083, merge_commit_sha: 'failure-c'),
          ]
        )
      end

      before do
        allow(subject).to receive(:notifier).and_return(notifier)
        allow(subject).to receive(:pickable_mrs).and_return(picks)
      end

      it 'attempts to cherry pick each merge request' do
        expect(ReleaseTools::GitlabClient).to receive(:cherry_pick).exactly(5).times

        # Unset the `TEST` environment so we call the stubbed `cherry_pick`
        ClimateControl.modify(TEST: nil) do
          subject.execute
        end
      end

      it 'posts a comment to each merge request' do
        stub_picking

        subject.execute

        expect(notifier).to have_received(:comment).exactly(5).times
      end

      it 'posts a summary comment to the preparation MR' do
        stub_picking

        subject.execute

        expect(notifier).to have_received(:summary)
      end

      it 'posts a blog post summary comment to the preparation MR' do
        stub_picking

        subject.execute

        expect(notifier).to have_received(:blog_post_summary)
      end
    end
  end
end
