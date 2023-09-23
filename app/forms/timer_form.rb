class TimerForm
  include ActiveModel::Model

  validates :hours, :minutes, :seconds, numericality: { greater_than_or_equal_to: 0 }

  attr_reader :timer

  def initialize(url:, hours:, minutes:, seconds:)
    @url = url
    @hours = hours
    @minutes = minutes
    @seconds = seconds
  end

  def submit
    return false unless valid?

    execution_time = ::Time.current + (hours.to_f * 3600 + minutes.to_f * 60 + seconds.to_f)
    @timer = ::Timer.new(execution_time:, url:)
    timer.save.tap { errors.merge!(timer.errors) }
  end

  private

  attr_reader :url, :hours, :minutes, :seconds
end
