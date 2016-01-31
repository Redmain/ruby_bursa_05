module ObservingOfDailyStatisticsPlayerMaterializedView

  def self.create_view_sql table_name='observing_of_daily_statistics_players'
    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT DISTINCT
            daily_statistics_players.id,
            daily_statistics_players.cid,
            daily_statistics_players.username,
            daily_statistics_players.registrationdate,
            daily_statistics_players.registrationcountry,
            COALESCE(history_of_players_changes.serial_id, daily_statistics_players.serial_id) AS serial_id,
            COALESCE(history_of_players_changes.anid, daily_statistics_players.anid) AS anid,
            affiliates.name AS affiliate_name,
            affiliates.username AS affiliate_username,
            conditions.type_of_transaction,
            MIN(
              CASE
                WHEN daily_players_statistics.deposits <> 0 THEN
                  daily_players_statistics.transaction_date
                END
            ) OVER(partition by daily_players_statistics.username, daily_players_statistics.serial_id) AS first_deposit
          FROM daily_statistics_players
            LEFT JOIN history_of_players_changes ON
              history_of_players_changes.id = (
                CASE
                  WHEN (
                    SELECT COUNT(*)
                    FROM history_of_players_changes
                    WHERE
                      history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id
                  ) >= 1 THEN
                    (
                      SELECT history_of_players_changes.id
                      FROM history_of_players_changes
                      WHERE
                        history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id
                      ORDER BY history_of_players_changes.date DESC
                      LIMIT 1
                    )
                  ELSE
                    0
                  END
              )
            LEFT JOIN daily_players_statistics ON
              daily_players_statistics.username = daily_statistics_players.username AND
              daily_players_statistics.serial_id = daily_statistics_players.serial_id
            LEFT JOIN trackers ON
              trackers.tracker_code = COALESCE(history_of_players_changes.serial_id, daily_statistics_players.serial_id)
            LEFT JOIN affiliates ON
              affiliates.id = trackers.affiliate_id
            LEFT JOIN tracker_conditions ON
              tracker_conditions.tracker_id = trackers.id
            LEFT JOIN conditions ON
              conditions.id = tracker_conditions.condition_id
      SQL
    end || ''
  end
end
