# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::TeamMember do
  describe '#initialize' do
    it 'accepts a name and a username' do
      member = described_class.new(name: 'John Doe', username: 'john')

      expect(member.name).to eq('John Doe')
      expect(member.username).to eq('john')
    end

    it 'requires a name' do
      expect { described_class.new(username: 'john') }.to raise_error(ArgumentError, 'missing keyword: name')
    end

    it 'requires a username' do
      expect { described_class.new(name: 'john') }.to raise_error(ArgumentError, 'missing keyword: username')
    end
  end
end
