# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::GitlabOpsClient do
  describe '.project_path' do
    it 'returns the correct project path' do
      project = double(path: 'foo/bar')

      expect(described_class.project_path(project)).to eq 'foo/bar'
    end
  end
end
