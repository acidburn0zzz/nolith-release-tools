require 'spec_helper'

require 'commit_author'

describe CommitAuthor do
  let(:git_author) { 'Your Name' }
  let(:custom_mapping) { { 'John Doe' => 'Mickael Mike' } }
  let(:custom_team) { Team.new(members: [TeamMember.new(name: 'Mickael Mike', username: 'mike')]) }

  subject { described_class.new(git_author, team: Team.new) }

  describe '#team' do
    it 'default to a Team object' do
      expect(subject.team).to be_a(Team)
    end

    it 'accepts a custom team' do
      commit_author = described_class.new(git_author, team: custom_team)

      expect(commit_author.team).to eq(custom_team)
    end
  end

  describe '#git_names_to_team_names' do
    let(:mapping_file) { File.expand_path('../../git_names_to_team_names.yml', __dir__) }

    context 'when mapping file exists' do
      before do
        expect(File).to receive(:exist?).with(mapping_file).and_return(true)
      end

      it 'loads git_names_to_team_names from a YAML file' do
        expect(YAML).to receive(:load_file).with(mapping_file).and_return(a: 'A')
        expect(subject.git_names_to_team_names).to eq(a: 'A')
      end
    end

    context 'when mapping file does not exist' do
      before do
        expect(File).to receive(:exist?).with(mapping_file).and_return(false)
      end

      it 'loads git_names_to_team_names from a YAML file' do
        expect(YAML).not_to receive(:load_file)
        expect(subject.git_names_to_team_names).to eq({})
      end
    end

    it 'accepts a custom git_names_to_team_names' do
      commit_author = described_class.new(git_author, team: custom_team, git_names_to_team_names: custom_mapping)

      expect(commit_author.git_names_to_team_names).to eq(custom_mapping)
    end
  end

  describe '#to_gitlab' do
    let(:name) { 'John Doe' }
    let(:username) { 'john' }

    subject { described_class.new(git_author, team: custom_team, git_names_to_team_names: custom_mapping) }

    shared_examples 'an author not from the team' do |git_name|
      it "returns their Git name: #{git_name}" do
        expect(subject.to_gitlab).to eq(git_name)
      end
    end

    shared_examples 'an author from the team' do |gitlab_username|
      it "returns their GitLab username: #{gitlab_username}" do
        expect(subject.to_gitlab).to eq("@#{gitlab_username}")
      end
    end

    context 'when author is not from the team' do
      it_behaves_like 'an author not from the team', 'Your Name' do
        let(:git_author) { 'Your Name' }
      end
    end

    context 'when author is from the team' do
      it_behaves_like 'an author from the team', 'mike' do
        let(:git_author) { 'John Doe' }
      end
    end
  end
end
