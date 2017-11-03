require 'spec_helper'

require 'team'

describe Team, vcr: { cassette_name: 'team' } do
  describe '#to_a' do
    it 'returns an array of TeamMember' do
      expect(subject.to_a.all? { |member| member.is_a?(TeamMember) }).to be(true)
    end

    [
      'lbennett',
      'axil',
      'ayufan',
      'rdavila',
      'nick.thomas',
      'godfat',
      'dbalexandre',
      'jarka',
      'balasankarc',
      'winh',
      'kushalpandya'
    ].each do |username|
      it "includes team member: #{username}" do
        expect(subject.to_a.find { |member| member.username == username }).to be_truthy
      end
    end
  end

  describe '#find_by_name' do
    context 'when the team member exists' do
      it 'returns a TeamMember' do
        member = subject.find_by_name('Rémy Coutable')

        expect(member.name).to eq('Rémy Coutable')
        expect(member.username).to eq('rymai')
      end
    end

    context 'when the team member does not exist' do
      it 'returns a TeamMember' do
        member = subject.find_by_name('John Doe')

        expect(member).to be_nil
      end
    end
  end
end
