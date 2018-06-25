require 'spec_helper'

require 'version'

describe HelmGitlabVersion do
  def gitlab_version(version_string)
    described_class.new(version_string)
  end

  def chart_version(version_string)
    HelmChartVersion.new(version_string)
  end

  describe "#new_chart_version" do
    context 'old app version is "master"' do
      it { expect(gitlab_version('10.8.1').new_chart_version('0.0.1', 'master')).to eq chart_version('0.0.2') }
      it { expect(gitlab_version('10.8.0').new_chart_version('0.0.1', 'master')).to eq chart_version('0.1.0') }
      it { expect(gitlab_version('11.0.0').new_chart_version('0.0.1', 'master')).to eq chart_version('1.0.0') }

      it 'increases chart version for a gitlab rc update from a non-rc' do
        expect(gitlab_version('11.0.0-rc1').new_chart_version('0.0.1', 'master')).to eq chart_version('1.0.0')
      end
    end

    context 'old app version is a valid gitlab version' do
      it { expect(gitlab_version('10.8.1').new_chart_version('0.0.1', '10.8.0')).to eq chart_version('0.0.2') }
      it { expect(gitlab_version('10.8.1').new_chart_version('0.0.1', '10.7.5')).to eq chart_version('0.1.0') }
      it { expect(gitlab_version('11.1.5').new_chart_version('0.0.1', '10.8.5')).to eq chart_version('1.0.0') }

      it 'ignores chart version changes when gitlab RC version has been bumped' do
        expect(gitlab_version('11.0.0-rc2').new_chart_version('0.0.1', '11.0.0-rc1')).to eq chart_version('0.0.1')
      end

      it 'ignores chart version changes when gitlab have been update off of an RC' do
        expect(gitlab_version('11.0.0').new_chart_version('0.0.1', '11.0.0-rc1')).to eq chart_version('0.0.1')
      end
    end
  end
end
