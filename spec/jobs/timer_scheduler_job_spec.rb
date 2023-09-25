require 'rails_helper'

RSpec.describe TimerSchedulerJob, type: :job do
  describe '#perform' do
    subject(:perform) { described_class.perform_now }

    before { stub_const('TimerSchedulerJob::BATCH_SIZE', 3) }

    let!(:pending_timer) { ::Timer.create!(execution_time: ::Time.current + 1.minute, url: 'https://g.com') }
    let!(:pending_timer2) { ::Timer.create!(execution_time: ::Time.current + 3.minutes, url: 'https://g.com') }
    let!(:future_pending_timer) { ::Timer.create!(execution_time: ::Time.current + 10.minutes, url: 'https://g.com') }
    let!(:executed_timer) do
      ::Timer.create!(execution_time: ::Time.current - 10.minutes, url: 'https://g.com', status: :executed)
    end
    let!(:overdue_scheduled_timer) do
      ::Timer.create!(execution_time: ::Time.current - 2.minutes, url: 'https://g.com', status: :scheduled)
    end
    let(:configured_job) { instance_double(::ActiveJob::ConfiguredJob, job_class: ::TimerExecutionJob) }

    it 'schedules timer execution jobs' do
      expect { perform }.to enqueue_job(::TimerExecutionJob).with(overdue_scheduled_timer)
                        .and enqueue_job(::TimerExecutionJob).with(pending_timer)
                        .and enqueue_job(::TimerExecutionJob).with(pending_timer2)
                        .and not_enqueue_job(::TimerSchedulerJob)
    end

    it 'updates status of scheduled jobs' do
      expect { perform }.to change { pending_timer.reload.status }.to('scheduled')
                        .and change { pending_timer2.reload.status }.to('scheduled')
                        .and not_change { overdue_scheduled_timer.reload.status }
                        .and not_change { future_pending_timer.reload.status }
                        .and not_change { executed_timer.reload.status }
    end

    context 'when there are more timers to be scheduled' do
      let!(:pending_timer3) { ::Timer.create!(execution_time: ::Time.current + 4.minutes, url: 'https://g.com') }

      it 'doesnt schedule extra timer execution job' do
        expect { perform }.to not_change { pending_timer3.reload.status }
      end

      it 'reschedules itself' do
        expect { perform }.to enqueue_job(::TimerSchedulerJob)
      end
    end
  end
end
