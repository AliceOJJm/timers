class CreateTimers < ActiveRecord::Migration[7.0]
  def change
    create_enum :timer_status, ['pending', 'scheduled', 'executed']

    create_table :timers do |t|
      t.string :url, null: false
      t.datetime :execution_time, index: true, null: false
      t.enum :status, enum_type: :timer_status, default: 'pending', null: false

      t.timestamps
    end
  end
end
