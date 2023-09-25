class TimerSchedulerJob < ::ApplicationJob
  BATCH_SIZE = 1000

  def perform
    timers = timers_scope.limit(BATCH_SIZE)
    timers.each { |timer| ::TimerExecutionJob.set(wait_until: timer.execution_time).perform_later(timer) }
    timers.update_all(status: :scheduled)
    self.class.perform_later if future_timers.exists?
  end

  private

  def future_timers
    ::Timer.where(status: :pending).where(execution_time: ..start_time + 5.minutes)
  end

  def overdue_timers
    ::Timer.where(status: [:pending, :scheduled]).where(execution_time: ..start_time - 15)
  end

  def timers_scope
    future_timers.or(overdue_timers).order(:execution_time)
  end

  def start_time
    @start_time ||= ::Time.current
  end
end
