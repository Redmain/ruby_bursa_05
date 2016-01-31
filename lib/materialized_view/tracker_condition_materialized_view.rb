module TrackerConditionMaterializedView

  def self.create_view_sql table_name='tracker_conditions'
    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT
            trackers.id AS tracker_id,
            COALESCE(trackers.condition_id, conditions.id) AS condition_id
          FROM trackers
            LEFT JOIN conditions ON CASE
                                      WHEN (SELECT COUNT(affiliates.condition_id) FROM affiliates WHERE (affiliates.id = trackers.affiliate_id)) = 1 THEN
                                        conditions.id = (SELECT affiliates.condition_id FROM affiliates WHERE (affiliates.id = trackers.affiliate_id) LIMIT 1)
                                      ELSE
                                        conditions.condition_type = 'default'
                                      END
          WHERE trackers.aasm_state = 'assigned'
          ORDER BY trackers.id ASC;
      SQL
    end || ''
  end
end
