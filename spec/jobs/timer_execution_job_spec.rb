require 'rails_helper'

RSpec.describe TimerExecutionJob, type: :job do
  describe '#perform' do
    subject(:perform) { described_class.perform_now(timer) }

    before { stub_request(:post, request_url) }

    let(:request_url) { "https://google.com/#{timer.id}" }

    context 'when timer is executed' do
      let(:timer) { ::Timer.create!(execution_time: ::Time.current, url: 'https://google.com', status: :executed) }

      it 'does not update timer status' do
        expect { perform }.not_to change { timer.reload.status }
      end

      it 'does not call the url' do
        perform
        expect(a_request(:post, request_url)).not_to have_been_made
      end
    end

    context 'when timer is not executed' do
      let(:timer) { ::Timer.create!(execution_time: ::Time.current, url: 'https://google.com') }

      shared_examples 'performs the request' do
        it 'updates timer status' do
          expect { perform }.to change { timer.reload.status }.from('pending').to('executed')
        end

        it 'calls the url' do
          perform
          expect(a_request(:post, request_url)).to have_been_made.once
        end
      end

      include_examples 'performs the request'

      context 'when the request_urluest times out' do
        before { stub_request(:post, request_url).to_timeout }

        include_examples 'performs the request'
      end
    end
  end
end
