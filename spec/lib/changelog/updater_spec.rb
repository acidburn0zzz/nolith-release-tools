require 'spec_helper'

require 'changelog/updater'
require 'changelog/markdown_generator'

describe Changelog::Updater do
  let(:contents) do
    File.read(File.expand_path("../../fixtures/changelog/CHANGELOG.md", __dir__))
  end

  describe '#insert' do
    it 'correctly inserts a new major release' do
      version = Version.new('8.11.0')
      generator = generator(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(generator).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the latest major release' do
      version = Version.new('8.10.5')
      generator = generator(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(generator).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the previous major release' do
      version = Version.new('8.9.7')
      generator = generator(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(generator).lines

      expect(contents).to have_inserted(version).at_line(24)
    end

    it 'correctly inserts a new patch of a legacy major release' do
      version = Version.new('8.8.8')
      generator = generator(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(generator).lines

      expect(contents).to have_inserted(version).at_line(54)
    end

    it 'correctly inserts entries for a pre-existing version header' do
      version = Version.new('8.9.6-ee')
      generator = generator(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(generator)

      expect(contents).to include(<<-MD.strip_heredoc)
        ## 8.9.6 (2016-07-11)

        - Change Z
        - Change Y
        - Change X
        - Change A
      MD
    end

    it 'does not add "No changes" to a pre-existing version header' do
      version = Version.new('8.9.6-ee')
      generator = Changelog::MarkdownGenerator.new(version, [])

      writer = described_class.new(contents, version)
      contents = writer.insert(generator)

      expect(contents).not_to include('No changes')
    end
  end

  def generator(version)
    Changelog::MarkdownGenerator.new(version, [
      double(id: 3, to_s: 'Change X', valid?: true),
      double(id: 2, to_s: 'Change Y', valid?: true),
      double(id: 1, to_s: 'Change Z', valid?: true),
    ])
  end

  matcher :have_inserted do |version|
    match do |contents|
      expect(contents[@line + 0]).to match("## #{version}")
      expect(contents[@line + 1]).to eq "\n"
      expect(contents[@line + 2]).to eq "- Change Z\n"
      expect(contents[@line + 3]).to eq "- Change Y\n"
      expect(contents[@line + 4]).to eq "- Change X\n"
      expect(contents[@line + 5]).to eq "\n"
    end

    chain :at_line do |line|
      @line = line
    end
  end
end
