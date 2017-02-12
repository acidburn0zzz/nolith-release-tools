# -*- encoding: utf-8 -*-

require 'spec_helper'
require './lib/gid/output/base'
require './lib/gid/tasks/task'
require './lib/gid/tasks/pick_into_stable_ce'
require './lib/gid/tasks/pick_into_stable_ee'
require './lib/gid/output/task_list'

describe Gid::Output::TaskList do
  describe '#new' do
    it 'works' do
      version = double('version')
      result = described_class.new(version)

      expect(result).not_to be_nil
    end
  end

  describe '#to_s' do
    it 'works' do
      version = double('version')
      task_list = described_class.new(version)
      result = task_list.to_s

      expect(result).not_to be_nil
    end
  end

  describe '#tasks' do
    it 'works' do
      version = double('version')
      task_list = described_class.new(version)
      result = task_list.tasks

      expect(result).not_to be_nil
    end
  end

  describe '#[]' do
    it 'works' do
      version = double('version')
      task_list = described_class.new(version)
      selected = 0

      expect(task_list[selected].class).to be < Gid::Tasks::Task
    end
  end
end
