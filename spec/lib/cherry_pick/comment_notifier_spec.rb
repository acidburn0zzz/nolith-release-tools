require 'spec_helper'

require 'cherry_pick'

describe CherryPick::CommentNotifier do
  let(:client) { spy('GitlabClient') }
  let(:version) { Version.new('11.4.0') }
  let(:prep_mr) { double(iid: 1, project_id: 2, url: 'https://example.com') }

  subject do
    described_class.new(version, prep_mr)
  end

  before do
    allow(subject).to receive(:client).and_return(client)
  end

  context 'with a successful pick' do
    it 'posts a success comment' do
      expected_url = prep_mr.url
      pick_result = CherryPick::Result.new(prep_mr, :success)

      subject.comment(pick_result)

      expect(client).to have_received(:create_merge_request_comment)
        .with(2, 1, SuccessMessageMatcher.new(version, expected_url))
    end
  end

  context 'with a failed pick' do
    it 'posts a failure comment' do
      conflicts = %w[foo.rb bar.md]
      pick_result = CherryPick::Result.new(prep_mr, :failure, conflicts)

      subject.comment(pick_result)

      expect(client).to have_received(:create_merge_request_comment)
        .with(2, 1, FailureMessageMatcher.new(version, conflicts))
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
