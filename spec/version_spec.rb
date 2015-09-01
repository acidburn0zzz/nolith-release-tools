require 'spec_helper'
require_relative '../lib/version'

describe Version do
  describe '.branch_name' do
    it { Version.branch_name('1.2.3').should == '1-2-stable' }
    it { Version.branch_name('1.23.45').should == '1-23-stable' }
    it { Version.branch_name('1.23.45.rc67').should == '1-23-stable' }
  end

  describe '.valid?' do
    it { Version.valid?('1.2.3').should be_truthy }
    it { Version.valid?('11.22.33').should be_truthy }
    it { Version.valid?('1.2.3.rc1').should be_truthy }
    it { Version.valid?('1.2.3.4').should be_falsey }
    it { Version.valid?('wow').should be_falsey }
  end
end
