# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Qa::IssuableOmitterByLabels do
  let(:permitted) do
    double("permitted mr", labels: %w[Create Documentation bug])
  end

  let(:unpermitted) do
    double("unpermitted mr", labels: %w[Plan Quality])
  end

  let(:permitted_but_no_team_labels) do
    double("documentation only mr", labels: %w[Documentation])
  end

  let(:merge_requests) do
    [
      permitted,
      unpermitted,
      permitted_but_no_team_labels
    ]
  end

  subject { described_class.new(merge_requests).execute }

  it 'excludes merge requests with Omit labels' do
    expect(subject).not_to include(unpermitted)
  end

  it 'includes permitted merge requests' do
    expect(subject).to include(permitted)
  end

  it 'excludes Documentation merge requests without team labels' do
    expect(subject).not_to include(permitted_but_no_team_labels)
  end
end
