require 'spec_helper'
require 'project/security_products_codequality'

describe Project::SecurityProductsCodequality do
  it_behaves_like 'project #remotes'

  describe '.path' do
    it { expect(described_class.path).to eq 'gitlab-org/security-products/codequality' }
  end
end
