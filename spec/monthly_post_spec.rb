require 'spec_helper'

require 'monthly_post'
require 'version'

describe MonthlyPost do
  describe '#post_title' do
    it "returns the post title" do
      version = Version.new('8.3.5.rc1')
      post = described_class.new(version)

      expect(post.post_title).to eq 'Release 8.3'
    end
  end

  describe '#render' do
    it "renders ordinal date headers" do
      time = Time.new(2015, 12, 22)
      post = described_class.new(spy, time)

      content = post.render

      aggregate_failures do
        expect(content).to include('### 11th: (7 working days before the 22nd)')
        expect(content).to include('### 14th: (6 working days before the 22nd)')
        expect(content).to include('### 15th: (5 working days before the 22nd)')
        expect(content).to include('### 16th: (4 working days before the 22nd)')
        expect(content).to include('### 17th: (3 working days before the 22nd)')
        expect(content).to include('### 18th: (2 working days before the 22nd)')
        expect(content).to include('### 21st: (1 working day before the 22nd)')
      end
    end

    it "renders the RC version" do
      version = Version.new('8.3.0')
      post = described_class.new(version)

      content = post.render

      expect(content).to include('GitLab 8.3.0.rc1 is available:')
    end

    it "renders stable branch names" do
      version = Version.new('8.3.0.rc1')
      post = described_class.new(version)

      content = post.render

      expect(content).to include('Merge `8-3-stable` into `8-3-stable-ee`')
    end

    it "renders the version number" do
      version = Version.new('8.3.0')
      post = described_class.new(version)

      content = post.render

      aggregate_failures do
        expect(content).to include("Create the '8.3.0' tag")
        expect(content).to include("Create the '8.3.0' version")
      end
    end
  end

  describe '#ordinal_date' do
    it "returns an ordinal date string" do
      time = Time.new(2015, 12, 22)
      post = MonthlyPost.new(double, time)

      expect(post.ordinal_date(5)).to eq '15th'
    end
  end
end
