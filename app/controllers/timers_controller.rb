class TimersController < ::ApplicationController
  def create
    form = ::TimerForm.new(url: params[:url], hours: params[:hours], minutes: params[:minutes], seconds: params[:seconds])

    if form.submit
      render json: present_timer(form.timer), status: 201
    else
      render json: { error: { code: :invalid_params, message: form.errors.full_messages.join("\n") } }, status: 422
    end
  end

  def show
    timer = ::Timer.find(params[:id])

    render json: present_timer(timer)
  end

  private

  def present_timer(timer)
    { id: timer.id, time_left: [(timer.execution_time - ::Time.current).to_i, 0].max }
  end
end
