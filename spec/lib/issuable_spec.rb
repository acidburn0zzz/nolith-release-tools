require 'spec_helper'

require 'issuable'
require 'gitlab_client'

class TestIssuable < Issuable
  protected

  def template
    "<%= RUBY_VERSION %>"
  end
end

describe Issuable do
  subject { TestIssuable.new }

  describe '#initialize' do
    it 'accepts arbitrary attributes as arguments' do
      issuable = TestIssuable.new(foo: 'bar')

      expect(issuable.foo).to eq('bar')
    end

    it 'accepts a block' do
      issuable = TestIssuable.new do |new_issuable|
        new_issuable.foo = 'bar'
      end

      expect(issuable.foo).to eq('bar')
    end
  end

  describe '#description' do
    it { expect(subject.description).to eq RUBY_VERSION }
  end

  describe '#project' do
    it 'returns Project::GitlabCe by default' do
      expect(subject.project).to eq(Project::GitlabCe)
    end

    context 'when a project is set' do
      subject { described_class.new(project: Project::GitlabEe) }

      it 'returns the given project' do
        expect(subject.project).to eq(Project::GitlabEe)
      end
    end
  end

  describe '#iid' do
    it 'delegates to remote_issuable' do
      remote_issuable = double(iid: 1234)
      allow(subject).to receive(:remote_issuable).and_return(remote_issuable)

      expect(subject.iid).to eq(1234)
    end
  end

  describe '#exists?' do
    context 'when remote subject does not exist' do
      before do
        allow(subject).to receive(:remote_issuable).and_return(nil)
      end

      it { is_expected.not_to be_exists }
    end

    context 'when remote subject exists' do
      before do
        allow(subject).to receive(:remote_issuable).and_return(double)
      end

      it { is_expected.to be_exists }
    end
  end

  describe '#create' do
    it { expect { subject.create }.to raise_error(NotImplementedError) }
  end

  describe '#remote_issuable' do
    it { expect { subject.remote_issuable }.to raise_error(NotImplementedError) }
  end

  describe '#url' do
    it { expect { subject.url }.to raise_error(NotImplementedError) }
  end
end
