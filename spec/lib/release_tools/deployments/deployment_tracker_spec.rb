# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Deployments::DeploymentTracker do
  describe '#track' do
    context 'when using a valid status' do
      let(:version) { '12.7.202001101501-94b8fd8d152.6fea3031ec9' }
      let(:tracker) { described_class.new }
      let(:parser) do
        instance_double(ReleaseTools::Deployments::DeploymentVersionParser)
      end

      let(:parsed_version) do
        ReleaseTools::Deployments::DeploymentVersionParser::DeploymentVersion
          .new('123', 'master', false)
      end

      before do
        allow(parser)
          .to receive(:parse)
          .with(version)
          .and_return(parsed_version)

        allow(ReleaseTools::Deployments::DeploymentVersionParser)
          .to receive(:new)
          .and_return(parser)
      end

      it 'tracks the deployment of GitLab and Gitaly' do
        allow(ReleaseTools::GitlabClient)
          .to receive(:file_contents)
          .with(
            ReleaseTools::Project::GitlabEe.path,
            'GITALY_SERVER_VERSION',
            '123'
          )
          .and_return('94b8fd8d152680445ec14241f14d1e4c04b0b5ab')

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_deployment)
          .with(
            ReleaseTools::Project::GitlabEe,
            'staging',
            'master',
            '123',
            'success',
            tag: false
          )

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_deployment)
          .with(
            ReleaseTools::Project::Gitaly,
            'staging',
            'master',
            '94b8fd8d152680445ec14241f14d1e4c04b0b5ab',
            'success'
          )

        tracker.track('staging', 'success', version)
      end

      it 'does not track the Gitaly deployment when Gitaly uses a tag version' do
        allow(ReleaseTools::GitlabClient)
          .to receive(:file_contents)
          .with(
            ReleaseTools::Project::GitlabEe.path,
            'GITALY_SERVER_VERSION',
            '123'
          )
          .and_return('1.2')

        expect(ReleaseTools::GitlabClient)
          .to receive(:create_deployment)
          .with(
            ReleaseTools::Project::GitlabEe,
            'staging',
            'master',
            '123',
            'success',
            tag: false
          )

        expect(ReleaseTools::GitlabClient)
          .not_to receive(:create_deployment)
          .with(
            ReleaseTools::Project::Gitaly,
            'staging',
            'master',
            '1.2',
            'success'
          )

        tracker.track('staging', 'success', version)
      end
    end

    context 'when using an invalid status' do
      it 'raises ArgumentError' do
        tracker = described_class.new
        version = '12.7.202001101501-94b8fd8d152.6fea3031ec9'

        expect { tracker.track('staging', 'foo', version) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
