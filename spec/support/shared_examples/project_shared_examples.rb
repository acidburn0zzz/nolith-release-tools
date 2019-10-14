# frozen_string_literal: true

RSpec.shared_examples 'project .remotes' do
  it 'returns all remotes by default' do
    expect(described_class.remotes).to eq(described_class::REMOTES.except(:security))
  end

  it 'returns only dev remote during a security release' do
    skip 'No dev remote' unless described_class::REMOTES.key?(:dev)

    expect(ReleaseTools::SharedStatus)
      .to receive(:security_release?)
      .and_return(true)

    expect(described_class.remotes).to eq(described_class::REMOTES.slice(:dev))
  end
end

RSpec.shared_examples 'project .to_s' do
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

RSpec.shared_examples 'project .security_group' do
  it 'returns security group with `security_remote` flag enabled' do
    enable_feature(:security_remote)

    expect(described_class.security_group).to eq 'gitlab-org/security'
  end

  it 'returns dev group with `security_remote` flag disabled' do
    disable_feature(:security_remote)

    expect(described_class.security_group).to eq described_class.dev_group
  end
end

RSpec.shared_examples 'project .security_path' do |path_when_enabled|
  it 'returns security path with `security_remote` flag enabled' do
    enable_feature(:security_remote)

    expect(described_class.security_path).to eq path_when_enabled
  end

  it 'returns dev path with `security_remote` flag disabled' do
    disable_feature(:security_remote)

    expect(described_class.security_path).to eq described_class.dev_path
  end
end
