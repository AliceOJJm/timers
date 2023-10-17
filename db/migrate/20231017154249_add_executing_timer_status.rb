class AddExecutingTimerStatus < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL
      ALTER TYPE timer_status ADD VALUE IF NOT EXISTS 'executing';
    SQL
  end

  # This should never be done on a production database without the thorough check and clean up
  def down
    execute <<-SQL
      DELETE
      FROM pg_enum
      WHERE enumlabel = 'executing' AND
            enumtypid = (SELECT oid from pg_type WHERE typname = 'timer_status')
    SQL
  end
end
