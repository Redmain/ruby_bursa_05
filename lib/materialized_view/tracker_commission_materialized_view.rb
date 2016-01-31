module TrackerCommissionMaterializedView

  def self.create_view_sql table_name='tracker_commissions'
    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT
            COALESCE(commissions.commission_type, 'none') AS commission_type,
            COALESCE(commissions.value, 0) AS value,
            trackers.id AS tracker_id
          FROM trackers
            LEFT JOIN conditions ON
              conditions.id = trackers.condition_id
            LEFT JOIN affiliates ON
              affiliates.id = trackers.affiliate_id
            LEFT JOIN commissions ON CASE
              WHEN (SELECT COUNT(commissions.commissionable_id) FROM commissions WHERE (commissions.commissionable_id = trackers.id AND commissions.commissionable_type = 'Tracker')) > 0 THEN
                commissions.commissionable_id = trackers.id AND commissions.commissionable_type = 'Tracker'
              WHEN (SELECT COUNT(commissions.commissionable_id) FROM commissions WHERE (commissions.commissionable_id = affiliates.id AND commissions.commissionable_type = 'Affiliate')) > 0 THEN
                commissions.commissionable_id = affiliates.id AND commissions.commissionable_type = 'Affiliate'
              WHEN (SELECT COUNT(commissions.commissionable_id) FROM commissions WHERE (commissions.commissionable_id = conditions.id AND commissions.commissionable_type = 'Condition')) > 0 THEN
                commissions.commissionable_id = conditions.id AND commissions.commissionable_type = 'Condition'
              END
          WHERE trackers.aasm_state = 'assigned'
          ORDER BY trackers.id ASC;
      SQL
    end || ''
  end
end
