# frozen_string_literal: true

RSpec.shared_examples 'project #remotes' do
  it 'returns all remotes by default' do
    expect(described_class.remotes).to eq(described_class::REMOTES)
  end

  it 'returns only dev remote during a security release' do
    skip 'No dev remote' unless described_class::REMOTES.key?(:dev)

    expect(ReleaseTools::SharedStatus)
      .to receive(:security_release?)
      .and_return(true)

    expect(described_class.remotes).to eq(described_class::REMOTES.slice(:dev))
  end
end

RSpec.shared_examples 'project #to_s' do
  it 'returns `path` by default' do
    expect(described_class.to_s).to eq(described_class.path)
  end

  it 'returns `dev_path` during a security release' do
    skip 'No dev remote' unless described_class::REMOTES.key?(:dev)

    expect(ReleaseTools::SharedStatus)
      .to receive(:security_release?)
      .and_return(true)

    expect(described_class.to_s).to eq(described_class.dev_path)
  end
end
