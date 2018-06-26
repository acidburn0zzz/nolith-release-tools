RSpec.shared_examples 'helm-release #execute' do |tag|
  tag = true if tag.nil?

  def execute(branch)
    release.execute
    repository.checkout(branch)
  end

  it 'creates a new branch and updates the version and appVersion in Chart.yaml, and a new tag' do
    expect(release).to receive(:bump_version).with(expected_chart_version, gitlab_version).once do
      original_chartfile = release.method(:chart_file)
      allow(release).to receive(:chart_file) do
        next original_chartfile.call unless repository.head.name == "refs/heads/#{branch}"
        instance_double(
          "ChartFile",
          version: expected_chart_version && HelmChartVersion.new(expected_chart_version),
          app_version: gitlab_version && HelmGitlabVersion.new(gitlab_version)
        )
      end
    end
    expect(release).to receive(:bump_version).with(expected_chart_version).once

    execute(branch)

    aggregate_failures do
      expect(repository.head.name).to eq "refs/heads/#{branch}"
      if tag
        expect(repository.tags["v#{expected_chart_version}"]).not_to be_nil
      else
        expect(repository.tags["v#{expected_chart_version}"]).to be_nil
      end
    end
  end
end
