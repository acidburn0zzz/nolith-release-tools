require 'spec_helper'

require 'merge_request'

describe MergeRequest do
  it_behaves_like 'issuable #create', :create_merge_request
  it_behaves_like 'issuable #remote_issuable', :find_merge_request
  it_behaves_like 'issuable #url', :merge_request_url
end
