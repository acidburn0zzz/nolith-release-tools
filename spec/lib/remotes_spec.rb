require 'spec_helper'
require 'remotes'

describe Remotes do
  describe '.remotes' do
    describe 'CE remotes' do
      context 'without the dev_only flag' do
        it 'returns all remotes' do
          expect(described_class.remotes(:ce)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git',
              gitlab: 'git@gitlab.com:gitlab-org/gitlab-ce.git',
              github: 'git@github.com:gitlabhq/gitlabhq.git'
            })
        end
      end

      context 'with the dev_only flag' do
        it 'returns only the dev remote' do
          expect(described_class.remotes(:ce, dev_only: true)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/gitlabhq.git'
            })
        end
      end
    end

    describe 'EE remotes' do
      context 'without the dev_only flag' do
        it 'returns all remotes' do
          expect(described_class.remotes(:ee)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git',
              gitlab: 'git@gitlab.com:gitlab-org/gitlab-ee.git'
            })
        end
      end

      context 'with the dev_only flag' do
        it 'returns only the dev remote' do
          expect(described_class.remotes(:ee, dev_only: true)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/gitlab-ee.git'
            })
        end
      end
    end

    describe 'Omnibus GitLab remotes' do
      context 'without the dev_only flag' do
        it 'returns all remotes' do
          expect(described_class.remotes(:omnibus_gitlab)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git',
              gitlab: 'git@gitlab.com:gitlab-org/omnibus-gitlab.git',
              github: 'git@github.com:gitlabhq/omnibus-gitlab.git'
            })
        end
      end

      context 'with the dev_only flag' do
        it 'returns only the dev remote' do
          expect(described_class.remotes(:omnibus_gitlab, dev_only: true)).
            to eq({
              dev: 'git@dev.gitlab.org:gitlab/omnibus-gitlab.git'
            })
        end
      end
    end
  end
end
