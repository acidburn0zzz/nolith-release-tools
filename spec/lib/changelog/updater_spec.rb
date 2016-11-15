require 'spec_helper'

require 'changelog/updater'

describe Changelog::Updater do
  let(:contents) do
    File.read(File.expand_path("../../fixtures/changelog/CHANGELOG.md", __dir__))
  end

  describe '#insert' do
    it 'correctly inserts a new major release' do
      version = Version.new('8.10.5')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(6)
    end

    it 'correctly inserts a new patch of the latest major release' do
      version = Version.new('8.10.5')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(6)
    end

    it 'correctly inserts a new patch of the previous major release' do
      version = Version.new('8.9.7')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(28)
    end

    it 'correctly inserts a new patch of a legacy major release' do
      version = Version.new('8.8.8')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(58)
    end

    it 'correctly inserts a new pre-release version header' do
      version = Version.new('8.15.0-rc1')
      markdown = "## 8.15.0\n\n"

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown)

      expect(contents).to include("## 8.15.0\n\n## 8.11.0")
    end

    it 'correctly inserts entries for a pre-existing version header of a pre-release' do
      version = Version.new('8.11.0-rc3')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown)

      expect(contents).to include(<<-MD.strip_heredoc)
        ## 8.11.0 (2016-08-22)

        - Change Z
        - Change Y
        - Change X
        - Change W
      MD
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
    markdown << "## #{version.to_ce.to_patch}\n\n"
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
