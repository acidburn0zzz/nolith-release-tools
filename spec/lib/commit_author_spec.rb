require 'spec_helper'

require 'commit_author'

describe CommitAuthor, vcr: { cassette_name: 'team' } do
  describe '#to_gitlab' do
    let(:git_author) { 'Your Name' }

    subject { described_class.new(git_author) }

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
      it_behaves_like 'an author from the team', 'rymai' do
        let(:git_author) { 'Rémy Coutable' }
      end
    end

    {
      'Luke "Jared" Bennett' => 'lbennett',
      'Achilleas Pipinellis' => 'axil',
      'Kamil Trzcinski' => 'ayufan',
      'Ruben Davila' => 'rdavila',
      'Nick Thomas' => 'nick.thomas',
      'Lin Jen-Shin' => 'godfat',
      'Douglas Barbosa Alexandre' => 'dbalexandre',
      'Jarka Kadlecova' => 'jarka',
      'Balasankar C' => 'balasankarc',
      'winniehell' => 'winh',
      'kushalpandya' => 'kushalpandya'
    }.each do |author_name, gitlab_username|
      context "when author is #{author_name}" do
        let(:git_author) { author_name }

        it "returns their GitLab username: #{gitlab_username}" do
          expect(subject.to_gitlab).to eq(gitlab_username)
          expect(subject.to_gitlab(reference: true)).to eq("@#{gitlab_username}")
        end
      end
    end
  end
end
