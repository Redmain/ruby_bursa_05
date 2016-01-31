module ModifiedAffiliatePaymentMaterializedView

  def self.create_view_sql table_name='modified_affiliate_payments'

    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT
            affiliate_payments.id,
            affiliate_payments.affiliate_id,
            affiliate_payments.tracker_id,
            affiliate_payments.date_of_payment,
            affiliate_payments.anid,
            affiliate_payments.cid,
            affiliate_payments.username,
            affiliate_payments.execution_condition,
            affiliate_payments.type_of_transaction,
            affiliate_payments.payment_size,
            affiliate_payments.created_at,
            affiliate_payments.updated_at,
            CASE
              WHEN (result.size_fine IS NULL) THEN
                affiliate_payments.profit
              WHEN (affiliate_payments.profit > result.size_fine) THEN
                affiliate_payments.profit - result.size_fine
              ELSE
                0
              END AS profit
          FROM affiliate_payments
            LEFT JOIN trackers ON
              affiliate_payments.tracker_id = trackers.id
            LEFT JOIN (
              SELECT
                penalizations.size_fine,
                penalizations.new_serial,
                history_of_players_changes.anid,
                daily_statistics_players.username
              FROM penalizations
                LEFT JOIN history_of_players_changes ON
                  penalizations.history_of_players_change_id = history_of_players_changes.id
                LEFT JOIN daily_statistics_players ON
                  history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id
              ) AS result ON
              result.username = affiliate_payments.username AND
              result.anid = affiliate_payments.anid AND
              result.new_serial = trackers.tracker_code
      SQL
    end || ''
  end
end
