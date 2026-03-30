class ReorderOrderServiceStatusEnumValues < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE order_services
      SET status = CASE status
        WHEN 7 THEN 0
        WHEN 0 THEN 1
        WHEN 1 THEN 2
        WHEN 2 THEN 3
        WHEN 3 THEN 4
        WHEN 5 THEN 5
        WHEN 4 THEN 6
        WHEN 6 THEN 7
        WHEN 8 THEN 8
        ELSE status
      END
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE order_services
      SET status = CASE status
        WHEN 0 THEN 7
        WHEN 1 THEN 0
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 5
        WHEN 6 THEN 4
        WHEN 7 THEN 6
        WHEN 8 THEN 8
        ELSE status
      END
    SQL
  end
end
