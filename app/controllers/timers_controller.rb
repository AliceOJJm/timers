class TimersController < ::ApplicationController
  IMMEDIATE_TIMER_SCHEDULER_LEEWAY = 305.seconds

  def create
    form = ::TimerForm.new(url: params[:url], hours: params[:hours], minutes: params[:minutes], seconds: params[:seconds])

    if form.submit
      timer = form.timer
      schedule_timer_execution(timer) if timer.execution_time < ::Time.current + IMMEDIATE_TIMER_SCHEDULER_LEEWAY
      render json: present_timer(timer), status: 201
    else
      render json: { error: { code: :invalid_params, message: form.errors.full_messages.join("\n") } }, status: 422
    end
  end

  def show
    timer = ::Timer.find(params[:id])

    render json: present_timer(timer)
  end

  private

  def schedule_timer_execution(timer)
    ::TimerExecutionJob.set(wait_until: timer.execution_time).perform_later(timer)
    timer.update_columns(status: :scheduled)
  end

  def present_timer(timer)
    { id: timer.id, time_left: [(timer.execution_time - ::Time.current).to_i, 0].max }
  end
end
