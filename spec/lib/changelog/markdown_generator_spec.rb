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

        Timecop.freeze(Time.local(1983, 7, 18))

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

    it 'sorts entries by type in TYPE_ORDER and by their entry ID in ascending order' do
      entries = [
        double(id: 5, to_s: "Change A", type: 'security', valid?: true),
        double(id: 3, to_s: "Change B", type: 'security', valid?: true),
        double(id: 1, to_s: "Change C", type: 'fixed',    valid?: true)
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change B\n- Change A\n- Change C\n")
    end

    it 'sorts entries without a type last' do
      entries = [
        double(id: 5, to_s: "Change A", type: 'security', valid?: true),
        double(id: 3, to_s: "Change B", type: 'security', valid?: true),
        double(id: 1, to_s: "Change C", type: nil,        valid?: true)
      ]

      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change B\n- Change A\n- Change C\n")
    end

    it 'sorts entries with invalid type last' do
      entries = [
        double(id: 5, to_s: "Change A", type: 'security', valid?: true),
        double(id: 3, to_s: "Change B", type: 'invalid',  valid?: true),
        double(id: 1, to_s: "Change C", type: 'invalid',  valid?: true)
      ]

      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change A\n- Change C\n- Change B\n")
    end

    it 'sorts entries without an ID last' do
      entries = [
        double(id: 5,   to_s: 'Change A', valid?: true, type: 'fixed'),
        double(id: nil, to_s: 'Change B', valid?: true, type: 'fixed'),
        double(id: 1,   to_s: 'Change C', valid?: true, type: 'fixed')
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change C\n- Change A\n- Change B\n")
    end

    it 'handles a non-numeric ID comparison' do
      entries = [
        double(id: 5,     to_s: 'Change A', valid?: true, type: 'fixed'),
        double(id: 'foo', to_s: 'Change B', valid?: true, type: 'fixed'),
        double(id: 1,     to_s: 'Change C', valid?: true, type: 'fixed')
      ]
      generator = described_class.new(spy, entries)

      markdown = generator.to_s

      expect(markdown).to match("- Change B\n- Change C\n- Change A\n")
    end

    it 'adds a "No changes" entry when there are no entries' do
      version = Version.new('1.2.3')
      generator = described_class.new(version, [])

      markdown = generator.to_s

      expect(markdown).to match("- No changes.\n")
    end
  end
end
