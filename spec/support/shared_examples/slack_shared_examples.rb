RSpec.shared_context 'Slack webhook' do
  let(:ci_slack_webhook_url) { 'http://foo.slack.com' }
  let(:ci_job_id) { '42' }

  let(:response_class) { Struct.new(:code) }
  let(:response) { response_class.new(200) }

  def expect_post(params)
    expect(HTTParty).to receive(:post).with(ci_slack_webhook_url, params)
  end

  around do |ex|
    ClimateControl.modify(CI_SLACK_WEBHOOK_URL: ci_slack_webhook_url, CI_JOB_ID: ci_job_id) do
      Timecop.freeze(Time.new(2018, 1, 4, 8, 30, 42)) do
        ex.run
      end
    end
  end
end
