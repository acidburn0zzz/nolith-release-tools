# frozen_string_literal: true

RSpec.shared_examples 'project #remotes' do
  it 'returns all remotes by default' do
    expect(described_class.remotes).to eq(described_class::REMOTES)
  end

  it 'returns only dev remote during a security release' do
    expect(ReleaseTools::SharedStatus)
      .to receive(:security_release?)
      .and_return(true)

    expect(described_class.remotes).to eq(described_class::REMOTES.slice(:dev))
  end
end
