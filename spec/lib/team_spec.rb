require 'spec_helper'

require 'team'

describe Team do
  let(:team_member_1) { TeamMember.new(name: 'Mickael Mike', username: 'mike') }

  describe '#initialize' do
    it 'default to the GitLab Inc team' do
      expect(HTTParty).to receive(:get)
        .with('https://gitlab.com/gitlab-com/www-gitlab-com/raw/master/data/team.yml')
        .and_return(double(body: YAML.dump([{ 'name' => 'Sid Sijbrandij', 'gitlab' => 'sytses' }])))

      expect(subject.find_by_name('Sid Sijbrandij').username).to eq('sytses')
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
        member = subject.find_by_name('Mickael Mike')

        expect(member.name).to eq('Mickael Mike')
        expect(member.username).to eq('mike')
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
