require 'spec_helper'

require 'cherry_pick'

describe CherryPick::CommentNotifier do
  let(:client) { spy('GitlabClient') }
  let(:version) { Version.new('11.4.0') }

  let(:prep_mr) do
    double(iid: 1, project_id: 2, url: 'https://example.com')
  end

  let(:merge_request) do
    double(iid: 3, project_id: 2, url: 'https://example.com')
  end

  subject do
    described_class.new(version, prep_mr)
  end

  before do
    allow(subject).to receive(:client).and_return(client)
  end

  describe '#comment' do
    context 'with a successful pick' do
      it 'posts a success comment' do
        expected_url = prep_mr.url
        pick_result = CherryPick::Result.new(merge_request, :success)

        subject.comment(pick_result)

        expect(client).to have_received(:create_merge_request_comment).with(
          merge_request.project_id,
          merge_request.iid,
          SuccessMessageArgument.new(version, expected_url)
        )
      end
    end

    context 'with a failed pick' do
      it 'posts a failure comment' do
        pick_result = CherryPick::Result.new(merge_request, :failure)

        subject.comment(pick_result)

        expect(client).to have_received(:create_merge_request_comment).with(
          merge_request.project_id,
          merge_request.iid,
          FailureMessageArgument.new(version)
        )
      end
    end
  end

  describe '#summary' do
    it 'posts a summary message to the preparation merge request' do
      picked = [double(url: 'a'), double(url: 'b')]
      unpicked = [double(url: 'c')]

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment).with(
        prep_mr.project_id,
        prep_mr.iid,
        SummaryMessageArgument.new(version, picked, unpicked)
      )
    end

    it 'excludes an empty picked list' do
      picked = []
      unpicked = [double(url: 'a')]

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment).with(
        prep_mr.project_id,
        prep_mr.iid,
        SummaryMessageArgument.new(version, picked, unpicked)
      )
    end

    it 'excludes an empty unpicked list' do
      picked = [double(url: 'a')]
      unpicked = []

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment).with(
        prep_mr.project_id,
        prep_mr.iid,
        SummaryMessageArgument.new(version, picked, unpicked)
      )
    end

    it 'does not post an empty message' do
      subject.summary([], [])

      expect(client).not_to have_received(:create_merge_request_comment)
    end
  end
end

class SuccessMessageArgument
  def initialize(version, expected_url)
    @version = version
    @expected_url = expected_url
  end

  def ===(other)
    other.include?("Automatically picked into #{@expected_url}") &&
      other.include?("will merge into\n`#{@version.stable_branch}`") &&
      other.include?("ready for `#{@version}`.") &&
      other.include?("/unlabel #{PickIntoLabel.reference(@version)}")
  end
end

class FailureMessageArgument
  def initialize(version)
    @version = version
  end

  def ===(other)
    other.include?("could not automatically be picked into\n`#{@version.stable_branch}`") &&
      other.include?("for `#{@version}`")
  end
end

class SummaryMessageArgument
  def initialize(version, picked, unpicked)
    @version = version
    @picked = picked
    @unpicked = unpicked
  end

  def ===(other)
    include_picked?(other) && include_unpicked?(other)
  end

  private

  def include_picked?(other)
    if @picked.empty?
      !other.include?("Successfully picked")
    else
      other.include?("Successfully picked the following merge requests:") &&
        @picked.all? { |p| other.include?("* #{p.url}") }
    end
  end

  def include_unpicked?(other)
    if @unpicked.empty?
      !other.include?("Failed to pick")
    else
      other.include?("Failed to pick the following merge requests:") &&
        @unpicked.all? { |p| other.include?("* #{p.url}") }
    end
  end
end
