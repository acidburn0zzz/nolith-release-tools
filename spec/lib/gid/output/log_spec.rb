# -*- encoding: utf-8 -*-

require 'open3'
require 'spec_helper'
require './lib/gid/output/base'
require './lib/gid/output/log'

describe Gid::Output::Log do
  let(:lines) { "one\ntwo\nthree\nfour\n" }

  before do
    stub_const("Config", double('Config').as_null_object)

    allow(Open3).to receive(:popen3).and_return(lines)
  end

  describe '#to_s' do
    it 'works' do
      log = described_class.new
      max_lines = 19
      result = log.to_s(max_lines)

      expect(result.lines.size).to eq(11)
    end
  end
end
