require 'spec_helper'

require 'commit_author'

describe CommitAuthor do
  let(:git_author) { 'Your Name' }
  let(:custom_mapping) { { 'John Doe' => 'Mickael Mike' } }
  let(:custom_team) { Team.new(members: [TeamMember.new(name: 'Mickael Mike', username: 'mike')]) }

  subject { described_class.new(git_author) }

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
    it 'loads git_names_to_team_names from a YAML file' do
      expect(subject.git_names_to_team_names).to be_a(Hash)
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
        expect(subject.to_gitlab(reference: true)).to eq(git_name)
      end
    end

    shared_examples 'an author from the team' do |gitlab_username|
      it "returns their GitLab username: #{gitlab_username}" do
        expect(subject.to_gitlab).to eq(gitlab_username)
        expect(subject.to_gitlab(reference: true)).to eq("@#{gitlab_username}")
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
