module ModifiedDailyStatisticsPlayerMaterializedView

  def self.create_view_sql table_name='modified_daily_statistics_players'
    unless ActiveRecord::Base.connection.table_exists? table_name
      <<-SQL
        CREATE MATERIALIZED VIEW #{table_name} AS
          SELECT DISTINCT ON (serial_id, anid, username) * FROM (
            SELECT
              daily_statistics_players.registrationdate,
              daily_statistics_players.serial_id,
              daily_statistics_players.anid,
              daily_statistics_players.cid,
              daily_statistics_players.username,
              daily_statistics_players.registrationcountry,
              daily_statistics_players.date_of_data,
              daily_statistics_players.processed,
              daily_statistics_players.created_at,
              daily_statistics_players.updated_at
            FROM daily_statistics_players
            UNION
            SELECT
              COALESCE(history_of_players_changes.date, daily_statistics_players.registrationdate) AS registrationdate,
              COALESCE(history_of_players_changes.serial_id, daily_statistics_players.serial_id) AS serial_id,
              COALESCE(history_of_players_changes.anid, daily_statistics_players.anid) AS anid,
              daily_statistics_players.cid,
              daily_statistics_players.username,
              daily_statistics_players.registrationcountry,
              daily_statistics_players.date_of_data,
              daily_statistics_players.processed,
              daily_statistics_players.created_at,
              daily_statistics_players.updated_at
            FROM daily_statistics_players
              INNER JOIN history_of_players_changes ON
                history_of_players_changes.daily_statistics_player_id = daily_statistics_players.id
          ) AS result
          ORDER BY result.serial_id, result.anid, result.username, result.registrationdate ASC
      SQL
    end || ''
  end
end
