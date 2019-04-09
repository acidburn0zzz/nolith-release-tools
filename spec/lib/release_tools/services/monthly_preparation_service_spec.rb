# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Services::MonthlyPreparationService do
  let(:internal_client) { spy('ReleaseTools::GitlabClient') }
  let(:version) { ReleaseTools::Version.new('12.1.0') }

  subject(:service) { described_class.new(version) }

  before do
    allow(service).to receive(:gitlab_client).and_return(internal_client)
  end

  # Simulate an error class from the `gitlab` gem
  def api_error(klass, message)
    error = double(parsed_response: double(message: message)).as_null_object

    klass.new(error)
  end

  # Unset the `TEST` environment variable that gets set by default
  def without_dry_run(&block)
    ClimateControl.modify(TEST: nil) do
      yield
    end
  end

  describe '#create_label', :silence_stdout do
    it 'does nothing on a dry run' do
      expect(ReleaseTools::PickIntoLabel).not_to receive(:create)

      service.create_label
    end

    it 'is idempotent' do
      allow(ReleaseTools::PickIntoLabel).to receive(:create)

      allow(internal_client).to receive(:create_branch)
        .and_raise(api_error(Gitlab::Error::BadRequest, 'Label already exists'))

      without_dry_run do
        expect { service.create_label }.not_to raise_error
      end
    end

    it 'creates the label' do
      label_spy = spy
      stub_const('ReleaseTools::PickIntoLabel', label_spy)

      without_dry_run do
        service.create_label
      end

      expect(label_spy).to have_received(:create).with(version)
    end
  end

  describe '#create_stable_branches', :silence_stdout do
    it 'does nothing on a dry run' do
      expect(internal_client).not_to receive(:create_branch)

      service.create_stable_branches
    end

    it 'is idempotent' do
      allow(internal_client).to receive(:create_branch)
        .and_raise(api_error(Gitlab::Error::Conflict, 'Branch already exists'))

      without_dry_run do
        expect { service.create_stable_branches }.not_to raise_error
      end
    end

    it 'creates the EE stable branch' do
      without_dry_run do
        service.create_stable_branches
      end

      expect(internal_client).to have_received(:create_branch)
        .with('12-1-stable-ee', 'master', ReleaseTools::Project::GitlabEe)
    end

    it 'creates the CE stable branch' do
      without_dry_run do
        service.create_stable_branches
      end

      expect(internal_client).to have_received(:create_branch)
        .with('12-1-stable', 'master', ReleaseTools::Project::GitlabCe)
    end

    it 'creates the Omnibus stable branches' do
      without_dry_run do
        service.create_stable_branches
      end

      expect(internal_client).to have_received(:create_branch)
        .with('12-1-stable-ee', 'master', ReleaseTools::Project::OmnibusGitlab)
      expect(internal_client).to have_received(:create_branch)
        .with('12-1-stable', 'master', ReleaseTools::Project::OmnibusGitlab)
    end
  end
end
