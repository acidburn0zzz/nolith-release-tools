require 'spec_helper'

require 'changelog/markdown_generator'
require 'version'

describe Changelog::MarkdownGenerator do
  describe '#to_s' do
    it 'includes the version header' do
      version = Version.new('1.2.3')
      generator = described_class.new(version, [])

      expect(generator.to_s).to match(/^## 1\.2\.3/)
    end

    describe 'includes the date in the version header' do
      it 'uses `Release.next_date` for monthly releases' do
        version = Version.new('9.2.0')
        generator = described_class.new(version, [])

        Timecop.freeze(Time.local(1983, 7, 2))

        expect(generator.to_s).to match(/\(1983-07-22\)$/)
      end

      it 'uses the current date for all other releases' do
        version = Version.new('1.2.3')
        generator = described_class.new(version, [])

        Timecop.freeze(Time.local(1983, 7, 2))

        expect(generator.to_s).to match(/\(1983-07-02\)$/)
      end
    end

    it 'includes an entry for each blob' do
      blobs = [
        double(to_entry: "- Change A"),
        double(to_entry: "- Change B"),
        double(to_entry: "- Change C")
      ]
      generator = described_class.new(spy, blobs)

      markdown = generator.to_s

      expect(markdown).to match("- Change A")
      expect(markdown).to match("- Change B")
      expect(markdown).to match("- Change C")
    end

    it 'adds a "No changes" entry for EE when there are no blobs' do
      version = Version.new('1.2.3-ee')
      generator = described_class.new(version, [])

      markdown = generator.to_s

      expect(markdown).to match("- No EE-specific changes.")
    end
  end
end
