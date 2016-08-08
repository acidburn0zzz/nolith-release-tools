require 'spec_helper'

require 'changelog/updater'

describe Changelog::Updater do
  let(:contents) do
    File.read(File.expand_path("../../fixtures/CHANGELOG.md", __dir__))
  end

  describe '#insert' do
    it 'correctly inserts a new major release' do
      version = Version.new('8.10.5')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the latest major release' do
      version = Version.new('8.10.5')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(2)
    end

    it 'correctly inserts a new patch of the previous major release' do
      version = Version.new('8.9.7')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(24)
    end

    it 'correctly inserts a new patch of a legacy major release' do
      version = Version.new('8.8.8')
      markdown = markdown(version)

      writer = described_class.new(contents, version)
      contents = writer.insert(markdown).lines

      expect(contents).to have_inserted(version).at_line(54)
    end
  end

  def markdown(version)
    markdown = ""
    markdown << "## #{version}\n\n"
    markdown << "- Change Z\n- Change Y\n- Change X\n"
  end

  matcher :have_inserted do |version|
    match do |contents|
      expect(contents[@line + 0]).to eq "## #{version}\n"
      expect(contents[@line + 1]).to eq "\n"
      expect(contents[@line + 2]).to eq "- Change Z\n"
      expect(contents[@line + 3]).to eq "- Change Y\n"
      expect(contents[@line + 4]).to eq "- Change X\n"
    end

    chain :at_line do |line|
      @line = line
    end
  end
end
