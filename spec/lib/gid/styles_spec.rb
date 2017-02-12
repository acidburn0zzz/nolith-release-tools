# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'dispel'
require './lib/gid/styles'

describe Gid::Styles do
  describe '#new' do
    it 'works' do
      screen = double('screen').as_null_object
      default_helpbar_length = double('default_helpbar_length')
      selected_element = double('selected_element')
      result = described_class.new(screen, default_helpbar_length, selected_element)

      expect(result).not_to be_nil
    end
  end
end
