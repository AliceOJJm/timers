class Timer < ActiveRecord::Base
  validates :execution_time, presence: true
  validates :url, presence: true,
                  format: /\A(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,63}(:[0-9]{1,5})?(\/.*)?\z/i
end
