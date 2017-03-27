require 'spec_helper'

require 'changelog/updater'

describe Changelog::Updater do
  let(:contents) do
    File.read(File.expand_path("../../fixtures/changelog/CHANGELOG.md", __dir__))
  end

  describe '#insert' do
    it 'correctly inserts a new major release' do
      version = Version.new('9.0.0')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new minor release' do
      version = Version.new('8.11.0')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the latest minor release' do
      version = Version.new('8.10.5')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the previous minor release' do
      version = Version.new('8.9.7')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(24)
    end

    it 'correctly inserts a new patch of a legacy minor release' do
      version = Version.new('8.8.8')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(54)
    end

    it 'correctly inserts entries for a pre-existing version header' do
      version = Version.new('8.9.6-ee')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown)

      expect(contents).to include(<<-MD.strip_heredoc)
        ## 8.9.6 (2016-07-11)

        - Change Z
        - Change Y
        - Change X
        - Change A
      MD
    end
  end

  def markdown(version)
    markdown = ""
    markdown << "## #{version}\n\n"
    markdown << "- Change Z\n- Change Y\n- Change X\n"
    markdown << "\n"
  end

  matcher :have_inserted do |version|
    match do |contents|
      expect(contents[@line + 0]).to eq "## #{version}\n"
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
