require 'spec_helper'

describe ReleaseTools::GitlabDevClient do
  describe '.project_path' do
    it 'returns the correct project dev_path' do
      project = double(dev_path: 'foo/bar')

      expect(described_class.project_path(project)).to eq 'foo/bar'
    end
  end
end
