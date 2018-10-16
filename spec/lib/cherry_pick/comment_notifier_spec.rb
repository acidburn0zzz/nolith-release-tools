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

        expect(client).to have_received(:create_merge_request_comment)
          .with(2, 3, SuccessMessageMatcher.new(version, expected_url))
      end
    end

    context 'with a failed pick' do
      it 'posts a failure comment' do
        conflicts = %w[foo.rb bar.md]
        pick_result = CherryPick::Result.new(merge_request, :failure, conflicts)

        subject.comment(pick_result)

        expect(client).to have_received(:create_merge_request_comment)
          .with(2, 3, FailureMessageMatcher.new(version, conflicts))
      end
    end
  end

  describe '#summary' do
    it 'posts a summary message to the preparation merge request' do
      picked = [ double(url: 'a'), double(url: 'b') ]
      unpicked = [ double(url: 'c') ]

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment)
        .with(2, 1, SummaryMessageMatcher.new(version, picked, unpicked))
    end

    it 'excludes an empty picked list' do
      picked = []
      unpicked = [ double(url: 'a') ]

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment)
        .with(2, 1, SummaryMessageMatcher.new(version, picked, unpicked))
    end

    it 'excludes an empty unpicked list' do
      picked = [ double(url: 'a') ]
      unpicked = []

      subject.summary(picked, unpicked)

      expect(client).to have_received(:create_merge_request_comment)
        .with(2, 1, SummaryMessageMatcher.new(version, picked, unpicked))
    end

    it 'does not post an empty message' do
      subject.summary([], [])

      expect(client).not_to have_received(:create_merge_request_comment)
    end
  end
end

class SuccessMessageMatcher
  def initialize(version, expected_url)
    @version = version
    @expected_url = expected_url
  end

  def ===(value)
    value.include?("Picked into #{@expected_url}") &&
      value.include?("will merge into `#{@version.stable_branch}`") &&
      value.include?("ready for `#{@version}`.") &&
      value.include?("/unlabel #{PickIntoLabel.reference(@version)}")
  end
end

class FailureMessageMatcher
  def initialize(version, conflicts)
    @version = version
    @conflicts = conflicts
  end

  def ===(value)
    value.include?("could not be picked into `#{@version.stable_branch}`") &&
      value.include?("for `#{@version}`") &&
      conflict_match?(value)
  end

  private

  def conflict_match?(value)
    if @conflicts.size == 1
      value.match?(/conflict:/) &&
        value.include?("* #{@conflicts.first}")
    else
      value.match?(/conflicts:/) &&
        @conflicts.all? { |c| value.include?("* #{c}") }
    end
  end
end

class SummaryMessageMatcher
  def initialize(version, picked, unpicked)
    @version = version
    @picked = picked
    @unpicked = unpicked
  end

  def ===(value)
    include_picked?(value) && include_unpicked?(value)
  end

  private

  def include_picked?(value)
    if @picked.empty?
      !value.include?("Successfully picked")
    else
      value.include?("Successfully picked the following merge requests:") &&
        @picked.all? { |p| value.include?("* #{p.url}") }
    end
  end

  def include_unpicked?(value)
    if @unpicked.empty?
      !value.include?("Failed to pick")
    else
      value.include?("Failed to pick the following merge requests:") &&
        @unpicked.all? { |p| value.include?("* #{p.url}") }
    end
  end
end
