# -*- encoding: utf-8 -*-

require 'spec_helper'
require './lib/gid/tasks/stable_mr'

describe Gid::Tasks::StableMr do
  let(:mr) { double('mr').as_null_object }
  let(:version) { 'v1.0' }

  describe '#new' do
    it 'works' do
      result = described_class.new(mr, version)

      expect(result).not_to be_nil
    end
  end

  describe '#to_s' do
    it 'works' do
      stable_mr = described_class.new(mr, version)
      result = stable_mr.to_s

      expect(result).not_to be_nil
    end
  end

  describe '#mr_note' do
    it 'works' do
      stable_mr = described_class.new(mr, version)
      result = stable_mr.mr_note

      expect(result).not_to be_nil
    end
  end
end
