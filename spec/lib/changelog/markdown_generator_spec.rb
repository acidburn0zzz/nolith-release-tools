require 'spec_helper'

require 'changelog/markdown_generator'
require 'version'

describe Changelog::MarkdownGenerator do
  describe 'initialize' do
    it 'only accepts valid entries' do
      entries = [
        double(valid?: false),
        double(valid?: true),
        double(valid?: false)
      ]

      generator = described_class.new(double, entries)

      expect(generator.entries.length).to eq(1)
    end
  end

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

      # TODO (rspeicher): Removable when we remove the corresponding hack
      it 'handles an EE release always returning 0 for its patch version' do
        version = Version.new('1.2.3-ee')
        generator = described_class.new(version, [])

        Timecop.freeze(Time.local(1983, 7, 2))

        expect(generator.to_s).to match(/\(1983-07-02\)$/)
      end
    end

    it 'sorts entries by their entry ID' do
      entries = [
        double(id: 5, to_s: "Change A", valid?: true),
        double(id: 3, to_s: "Change B", valid?: true),
        double(id: 1, to_s: "Change C", valid?: true)
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change C\n- Change B\n- Change A\n")
    end

    it 'sorts entries without an ID last' do
      entries = [
        double(id: 5,   to_s: "Change A", valid?: true),
        double(id: nil, to_s: "Change B", valid?: true),
        double(id: 1,   to_s: "Change C", valid?: true)
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change C\n- Change A\n- Change B\n")
    end

    it 'adds a "No changes" entry when there are no entries' do
      version = Version.new('1.2.3')
      generator = described_class.new(version, [])

      markdown = generator.to_s

      expect(markdown).to match("- No changes.\n")
    end
  end
end
