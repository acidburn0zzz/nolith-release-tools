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

  describe '#description' do
    it { expect(subject.description).to eq RUBY_VERSION }
  end

  describe '#create' do
    it { expect { subject.create }.to raise_error(NotImplementedError) }
  end

  describe '#remote_issuable' do
    it { expect { subject.remote_issuable }.to raise_error(NotImplementedError) }
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

  describe '#url' do
    context 'when remote subject does not exist' do
      before do
        allow(subject).to receive(:remote_issuable).and_return(nil)
      end

      it { expect(subject.url).to eq '' }
    end

    context 'when remote subject exists' do
      before do
        allow(subject).to receive(:remote_issuable).and_return(double)
      end

      it 'delegates to _url which is not implemented' do
        expect(subject).to receive(:_url).and_call_original

        expect { subject.url }.to raise_error(NotImplementedError)
      end
    end
  end
end
