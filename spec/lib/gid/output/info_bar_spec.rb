# -*- encoding: utf-8 -*-

require 'spec_helper'
require './lib/gid/output/base'
require './lib/gid/output/info_bar'

describe Gid::Output::InfoBar do
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
      info_bar = described_class.new(version)
      result = info_bar.to_s

      expect(result).not_to be_nil
    end
  end
end
