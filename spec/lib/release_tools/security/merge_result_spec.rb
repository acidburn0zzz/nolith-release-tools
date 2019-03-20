# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTools::Security::MergeResult do
  describe '.from_array' do
    it 'returns a MergeResult' do
      mr1 = double(:merge_request)
      mr2 = double(:merge_request)
      mrs = [[true, mr1], [false, mr2]]

      expect(described_class)
        .to receive(:new)
        .with(merged: [mr1], not_merged: [mr2])

      described_class.from_array(mrs)
    end
  end

  describe '#not_merged_slack_attachment_fields' do
    it 'returns the attachments' do
      mr1 = double(
        :merge_request,
        target_branch: 'master',
        web_url: 'foo',
        iid: 1
      )

      mr2 = double(
        :merge_request,
        target_branch: 'master',
        web_url: 'bar',
        iid: 2
      )

      mr3 = double(
        :merge_request,
        target_branch: 'foo',
        web_url: 'baz',
        iid: 3
      )

      result = described_class
        .new(not_merged: [mr1, mr2, mr3])
        .not_merged_slack_attachment_fields

      expect(result).to eq([
        { title: 'Branch: master', value: '<foo|!1>, <bar|!2>', short: false },
        { title: 'Branch: foo', value: '<baz|!3>', short: false },
      ])
    end
  end

  describe '#slack_attachments' do
    context 'when there are no merge requests' do
      it 'returns an empty array' do
        expect(described_class.new.slack_attachments).to eq([])
      end
    end

    context 'when there are merged merge requests' do
      it 'includes an attachment for the merged merge requests' do
        result = described_class.new(merged: [double(:merge_request)])

        expect(result.slack_attachments).to eq([
          {
            fallback: 'Merged: 1',
            title: ':heavy_check_mark: Merged: 1',
            color: 'good'
          }
        ])
      end
    end

    context 'when there are unmerged merge requests' do
      it 'includes an attachment for the unmerged merge requests' do
        mr = double(
          :merge_request,
          target_branch: 'foo',
          web_url: 'baz',
          iid: 3
        )

        result = described_class.new(not_merged: [mr])

        expect(result.slack_attachments).to eq([
          {
            fallback: 'Not merged: 1',
            title: ':x: Not merged: 1',
            color: 'danger',
            fields: [
              { title: 'Branch: foo', value: '<baz|!3>', short: false }
            ]
          }
        ])
      end
    end

    context 'when there are merged and unmerged merge requests' do
      it 'includes both attachments' do
        unmerged = double(
          :merge_request,
          target_branch: 'foo',
          web_url: 'baz',
          iid: 3
        )

        result = described_class
          .new(merged: [double(:merge_request)], not_merged: [unmerged])

        expect(result.slack_attachments).to eq([
          {
            fallback: 'Merged: 1',
            title: ':heavy_check_mark: Merged: 1',
            color: 'good'
          },
          {
            fallback: 'Not merged: 1',
            title: ':x: Not merged: 1',
            color: 'danger',
            fields: [
              { title: 'Branch: foo', value: '<baz|!3>', short: false }
            ]
          }
        ])
      end
    end
  end
end
