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

    it 'includes each entry' do
      entries = [
        double(to_s: "Change A"),
        double(to_s: "Change B"),
        double(to_s: "Change C")
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change A\n")
      expect(markdown).to match("- Change B\n")
      expect(markdown).to match("- Change C\n")
    end

    it 'adds a "No changes" entry when there are no entries' do
      version = Version.new('1.2.3')
      generator = described_class.new(version, [])

      markdown = generator.to_s

      expect(markdown).to match("- No changes.\n")
    end
  end
end
