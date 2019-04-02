# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Helm::VersionManager do
  describe "#self.derive_chart_version" do
    let(:manager) { described_class }

    context 'old app version is "master"' do
      let(:chart) { stubbed_chart(version: '0.0.1', app_version: 'master') }

      it { expect(manager.derive_chart_version(chart, gitlab_version('10.8.1'))).to eq chart_version('0.0.2') }
      it { expect(manager.derive_chart_version(chart, gitlab_version('10.8.0'))).to eq chart_version('0.1.0') }
      it { expect(manager.derive_chart_version(chart, gitlab_version('11.0.0'))).to eq chart_version('1.0.0') }

      it 'increases chart version for a gitlab rc update from a non-rc' do
        expect(manager.derive_chart_version(chart, gitlab_version('11.0.0-rc1'))).to eq chart_version('1.0.0')
      end
    end

    context 'old app version is a valid gitlab version' do
      let(:chart) { stubbed_chart(version: '0.0.1', app_version: '10.8.0') }

      it { expect(manager.derive_chart_version(chart, gitlab_version('10.8.1'))).to eq chart_version('0.0.2') }
      it { expect(manager.derive_chart_version(chart, gitlab_version('10.9.1'))).to eq chart_version('0.1.0') }
      it { expect(manager.derive_chart_version(chart, gitlab_version('11.1.5'))).to eq chart_version('1.0.0') }
    end

    context 'old app version is an RC' do
      let(:chart) { stubbed_chart(version: '0.0.1', app_version: '11.0.0-rc1') }

      it 'ignores chart version changes when gitlab RC version has been bumped' do
        expect(manager.derive_chart_version(chart, gitlab_version('11.0.0-rc2'))).to eq chart_version('0.0.1')
      end

      it 'ignores chart version changes when gitlab have been update off of an RC' do
        expect(manager.derive_chart_version(chart, gitlab_version('11.0.0'))).to eq chart_version('0.0.1')
      end
    end
  end

  def gitlab_version(version_string)
    ReleaseTools::HelmGitlabVersion.new(version_string)
  end

  def chart_version(version_string)
    ReleaseTools::HelmChartVersion.new(version_string)
  end

  def stubbed_chart(version: '0.0.1', app_version: '0.0.1')
    instance_double(
      "ChartFile",
      version: version && ReleaseTools::HelmChartVersion.new(version),
      app_version: app_version && ReleaseTools::HelmGitlabVersion.new(app_version)
    )
  end
end
