# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Team do
  let(:team_member_1) { ReleaseTools::TeamMember.new(name: 'Mickael Mike', username: 'mike') }

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

    context 'when we are finding core members' do
      let(:core_member_wanted) { described_class::CORE_TEAM.first }
      let(:core_member_not_wanted) { described_class::CORE_TEAM.last }

      subject do
        described_class.new(included_core_members: [core_member_wanted])
      end

      before do
        stub_request(:get, described_class::USERS_API_URL)
          .with(query: { per_page: 100, page: 0 })
          .to_return(headers: { 'x-next-page': '' }, body:
            JSON.dump(
              [
                { name: core_member_wanted,
                  username: core_member_wanted },
                { name: core_member_not_wanted,
                  username: core_member_not_wanted }
              ]))
      end

      it 'does not find the core members we do not include' do
        member = subject.find_by_name(core_member_not_wanted)

        expect(member).to be_nil
      end

      it 'returns the core members we do want to include' do
        member = subject.find_by_name(core_member_wanted)

        expect(member.name).to eq(core_member_wanted)
        expect(member.username).to eq(core_member_wanted)
      end
    end

    context 'when the team member name contains (OOO)' do
      let(:team_member_1) do
        ReleaseTools::TeamMember.new(name: 'Bot (OOO)', username: 'bot')
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
