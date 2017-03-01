require 'spec_helper'
require 'release/base_release'

describe Release::BaseRelease do
  describe 'security_release?' do
    it 'returns true when initialized with security: true' do
      expect(described_class.new('8.0.1', security: true)).to be_security_release
    end

    it 'returns false when no security: true was provided in initialization' do
      expect(described_class.new('8.0.1')).not_to be_security_release
    end
  end
end
