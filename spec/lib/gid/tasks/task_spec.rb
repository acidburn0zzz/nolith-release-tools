# -*- encoding: utf-8 -*-

require 'spec_helper'
require './lib/gid/tasks/task'

describe Gid::Tasks::Task do
  describe '#new' do
    it 'works' do
      options = double('options')
      result = described_class.new(options)

      expect(result).not_to be_nil
    end
  end

  describe '#run!' do
    it 'works' do
      options = double('options')
      task = described_class.new(options)
      result = task.run!

      expect(result).not_to be_nil
    end
  end
end
