require 'spec_helper'

require 'issue'

describe Issue do
  it_behaves_like 'issuable #create', :create_issue
  it_behaves_like 'issuable #remote_issuable', :find_issue
  it_behaves_like 'issuable #url', :issue_url

  describe '#confidential?' do
    it { expect(subject).not_to be_confidential }
  end
end
