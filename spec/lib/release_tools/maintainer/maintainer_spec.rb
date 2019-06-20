# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Maintainer do
  describe '.project_maintainer?' do
    subject { described_class }

    before do
      allow(subject).to receive(:client).and_return(client)
    end

    let(:client) do
      spy(
        team_members: [
          double(username: 'james', access_level: 20),
          double(username: 'ZJ', access_level: 40) # Test case-sensitivity
        ]
      )
    end

    context 'when the user is a maintainer' do
      it 'returns true' do
        expect(subject.project_maintainer?('zj', ReleaseTools::Project::Gitaly)).to be(true)
      end
    end

    context 'when the user is not a maintainer' do
      it 'returns false' do
        expect(subject.project_maintainer?('james', ReleaseTools::Project::Gitaly)).to be(false)
      end
    end
  end
end
