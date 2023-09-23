require 'rails_helper'

RSpec.describe TimersController, type: :controller do
  around { |example| freeze_time { example.run } }

  describe '#create' do
    subject(:create) { post(:create, params:) }

    let(:valid_params) { { hours: 0, minutes: 10, seconds: 1, url: 'https://google.com' } }

    context 'with valid params' do
      let(:params) { valid_params }

      it 'resturns timer data' do
        create
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq({ 'id' => ::Timer.last.id, 'time_left' => 601 })
      end

      it 'creates the timer' do
        expect { create }.to change { ::Timer.count }.by(1)
        timer = ::Timer.last
        expect(timer.execution_time).to eq(::Time.current + 601)
        expect(timer.url).to eq('https://google.com')
      end
    end

    context 'with invalid params' do
      shared_examples 'does not create the timer' do
        it 'does not create the timer' do
          expect { create }.not_to change { ::Timer.count }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      shared_examples 'invalid time param' do |param_key|
        context "with invalid #{param_key} param: string" do
          let(:params) { valid_params.dup.merge(param_key => 'text') }

          include_examples 'does not create the timer'

          it 'returns an error' do
            create
            expect(response.parsed_body).to eq(
              { 'error' => { 'code' => 'invalid_params', 'message' => "#{param_key.to_s.capitalize} is not a number" } }
            )
          end
        end

        context "with invalid #{param_key} param: negative" do
          let(:params) { valid_params.dup.merge(param_key => -1) }

          include_examples 'does not create the timer'

          it 'returns an error' do
            create
            expect(response.parsed_body).to eq(
              {
                'error' => {
                  'code' => 'invalid_params',
                  'message' => "#{param_key.to_s.capitalize} must be greater than or equal to 0"
                }
              }
            )
          end
        end
      end

      include_examples 'invalid time param', :hours
      include_examples 'invalid time param', :minutes
      include_examples 'invalid time param', :seconds

      context 'with invalid url param' do
        let(:params) { valid_params.merge(url: 'text') }

        include_examples 'does not create the timer'

        it 'returns an error' do
          create
          expect(response.parsed_body).to eq(
            { 'error' => { 'code' => 'invalid_params', 'message' => 'Url is invalid' } }
          )
        end
      end

      context 'with multiple invalid params' do
        let(:params) { { hours: 'text', minutes: -1, url: 'text' } }

        include_examples 'does not create the timer'

        it 'returns an error' do
          create
          expect(response.parsed_body).to eq(
            { 'error' => {
                'code' => 'invalid_params',
                'message' => "Hours is not a number\nMinutes must be greater than or equal to 0\nSeconds is not a number"              }
            }
          )
        end
      end
    end
  end

  describe '#show' do
    subject(:show) { get(:show, params: { id: }) }

    context 'with valid id param' do
      let(:timer) { ::Timer.create!(execution_time: ::Time.current + 114, url: 'https://google.com') }
      let(:id) { timer.id }

      it 'resturns timer data' do
        show
        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq({ 'id' => timer.id, 'time_left' => 114 })
      end
    end

    context 'with invalid id param' do
      let(:id) { 1000 }

      it { expect { show }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
