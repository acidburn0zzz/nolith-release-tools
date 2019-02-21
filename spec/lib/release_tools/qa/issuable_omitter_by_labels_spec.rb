require 'spec_helper'

describe ReleaseTools::Qa::IssuableOmitterByLabels do
  let(:omit_labels) { ['Omit'] }

  let(:unpermitted) { double("unpermitted mr", labels: %w[Discussion Omit]) }
  let(:permitted) { double("permitted mr", labels: %w[Platform bug]) }

  let(:merge_requests) { [unpermitted, permitted] }

  subject { described_class.new(merge_requests, omit_labels).execute }

  it 'excludes Merge Requests with omitted labels' do
    expect(subject).not_to include(unpermitted)
  end

  it 'permitted Merge Requests remain' do
    expect(subject).to include(permitted)
  end
end
