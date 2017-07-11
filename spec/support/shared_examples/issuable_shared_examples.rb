RSpec.shared_examples 'issuable #create' do |create_issuable_method|
  it 'calls GitlabClient.create_issue' do
    expect(GitlabClient).to receive(create_issuable_method).with(subject, Project::GitlabCe)

    subject.create
  end
end

RSpec.shared_examples 'issuable #remote_issuable' do |find_issuable_method|
  it 'delegates to GitlabClient' do
    expect(GitlabClient).to receive(find_issuable_method).with(subject, Project::GitlabCe)

    subject.remote_issuable
  end

  context 'when remote issuable does not exist' do
    before do
      expect(GitlabClient).to receive(find_issuable_method).once
        .with(subject, Project::GitlabCe).and_return(nil)
    end

    it 'memoizes the remote issuable' do
      2.times { subject.remote_issuable }
    end
  end

  context 'when remote issuable exists' do
    before do
      expect(GitlabClient).to receive(find_issuable_method).once
        .with(subject, Project::GitlabCe).and_return(double)
    end

    it 'memoizes the remote issuable' do
      2.times { subject.remote_issuable }
    end
  end
end

RSpec.shared_examples 'issuable #url' do |issuable_url_method|
  it 'returns the remote_issuable url' do
    expect(GitlabClient).to receive(issuable_url_method).with(subject, Project::GitlabCe).and_return('https://example.com/')
    expect(subject.url).to eq 'https://example.com/'
  end
end
