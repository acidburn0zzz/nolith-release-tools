require 'spec_helper'

require 'team'

describe Team do
  let(:team_member_1) { TeamMember.new(name: 'Mickael Mike', username: 'mike') }

  describe '#initialize' do
    it 'downloads GitLab EE members via API', vcr: { cassette_name: 'gitlab-ee-users' } do
      expect(subject.find_by_name('Dmitriy Zaporozhets').username).to eq('dzaporozhets')
    end

    it 'accepts a custom team' do
      team = described_class.new(members: [team_member_1])

      expect(team.to_a).to eq([team_member_1])
    end
  end

  describe '#to_a' do
    subject { described_class.new(members: [team_member_1]) }

    it 'returns an array of TeamMember' do
      expect(subject.to_a).to eq([team_member_1])
    end
  end

  describe '#find_by_name' do
    subject { described_class.new(members: [team_member_1]) }

    context 'when the team member exists' do
      it 'returns a TeamMember' do
        member = subject.find_by_name(team_member_1.name)

        expect(member).to eq(team_member_1)
      end
    end

    context 'when the team member does not exist' do
      it 'returns nil' do
        member = subject.find_by_name('John Doe')

        expect(member).to be_nil
      end
    end

    context 'when the team member name contains (OOO)' do
      let(:team_member_1) do
        TeamMember.new(name: 'Bot (OOO)', username: 'bot')
      end

      it 'returns the TeamMember' do
        member = subject.find_by_name('Bot')

        expect(member).to eq(team_member_1)
      end
    end

    context 'when finding the member with name contains (OOO)' do
      it 'returns the TeamMember' do
        member = subject.find_by_name("#{team_member_1.name} (OOO)")

        expect(member).to eq(team_member_1)
      end
    end

    context 'when finding the member with upper cases' do
      it 'returns the TeamMember' do
        member = subject.find_by_name(team_member_1.name.upcase)

        expect(member).to eq(team_member_1)
      end
    end

    context 'when finding the member with extra spaces in between' do
      it 'returns the TeamMember' do
        member = subject.find_by_name('Mickael (MM) Mike  ')

        expect(member).to eq(team_member_1)
      end
    end
  end
end
