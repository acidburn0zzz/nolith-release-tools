require 'spec_helper'

require 'qa/formatters/merge_requests_formatter'

describe Qa::Formatters::MergeRequestsFormatter do
  let(:mr1) { mr_double("mr1", %w[Team\ 1 TypeA]) }
  let(:mr2) { mr_double("mr2", %w[Team1 Without\ Type]) }
  let(:mr3) { mr_double("mr3", %w[Without\ Team TypeC]) }

  let(:merge_requests) do
    {
      "Team 1" => {
        "TypeA" => [mr1],
        "uncategorized" => [mr2]
      },
      "uncategorized" => [mr3]
    }
  end

  subject { described_class.new(merge_requests) }

  describe '#lines' do
    it 'has the correct contents' do
      expect(subject.lines).to be_a(Array)
      expect(subject.lines.size).to eq(10)
      expect(subject.lines).to eq(
        [
          "### Team 1 ~\"Team 1\" \n",
          "#### TypeA ~\"TypeA\" \n",
          mr_string(mr1),
          "\n\n----\n\n",
          "#### uncategorized ~\"uncategorized\" \n",
          mr_string(mr2),
          "\n\n----\n\n",
          "### uncategorized ~\"uncategorized\" \n",
          mr_string(mr3),
          "\n\n----\n\n",
        ]
      )
    end

    context 'for community contribution' do
      let(:mr1) { mr_double("mr1", %w[Team1 TypeA Community\ Contribution]) }

      it 'mentions the merger' do
        expect(subject.lines[2]).to include(mr1.merged_by.username)
      end
    end
  end
end

def mr_string(merge_request)
  labels = merge_request.labels.map { |l| "~\"#{l}\"" }.join(' ')
  "- [ ] @#{merge_request.author.username} | [#{merge_request.title}](#{merge_request.web_url}) #{labels}"
end

def mr_double(identifier, labels)
  double(
    identifier,
    "labels" => labels,
    "title" => "mr1 Title",
    "author" => double("username" => "mr1_author"),
    "assignee" => double("username" => "mr1_assignee"),
    "sha" => "mr1_sha",
    "merge_commit_sha" => "mr1_merge_commit_sha",
    "web_url" => "mr1_web_url",
    "merged_by" => double("username": "mr1_merged_by")
  )
end
