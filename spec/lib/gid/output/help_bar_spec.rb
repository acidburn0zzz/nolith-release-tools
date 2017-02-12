# -*- encoding: utf-8 -*-

require 'spec_helper'
require './lib/gid/output/base'
require './lib/gid/output/help_bar'

describe Gid::Output::HelpBar do
  describe '#to_s' do
    it 'works' do
      help_bar = described_class.new
      key = double('key').as_null_object
      result = help_bar.to_s(key)

      expect(result).not_to be_nil
    end
  end

  describe '#default_message_length' do
    it 'works' do
      help_bar = described_class.new
      result = help_bar.default_message_length

      expect(result).not_to be_nil
    end
  end
end
