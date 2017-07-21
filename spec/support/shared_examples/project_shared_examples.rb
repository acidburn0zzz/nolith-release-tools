RSpec.shared_examples 'project #remotes' do
  it 'returns all remotes by default' do
    expect(described_class.remotes).to eq(described_class::REMOTES)
  end

  it 'returns only dev remote with dev_only flag' do
    expect(described_class.remotes(dev_only: true))
      .to eq(described_class::REMOTES.slice(:dev))
  end
end
